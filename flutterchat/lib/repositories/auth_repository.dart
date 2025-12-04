import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/saved_account.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

// 定义 Repository Provider
// keepAlive: true 确保 AuthRepository 全局单例，因为认证状态是 App 的生命线
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    api: ref.watch(apiServiceProvider),
    accountService: ref.watch(accountServiceProvider),
    ref: ref,
  );
}

class AuthRepository {
  final ApiService _api;
  final AccountService _accountService;
  final AuthRepositoryRef _ref;

  AuthRepository({
    required ApiService api,
    required AccountService accountService,
    required AuthRepositoryRef ref,
  })  : _api = api,
        _accountService = accountService,
        _ref = ref;

  // ==========================================
  // 1. 登录 (Login)
  // ==========================================

  /// 执行登录
  /// 成功后会自动保存 Token 和 账户历史
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      logger.i("🔐 [AuthRepo] 开始登录: $username");

      // 1. 调用 API
      final response = await _api.login(username: username, password: password);

      // 2. 持久化 Token (关键：确保后续 API 调用能带上 Token)
      await _api.saveToken(response.token);

      // 3. 更新全局用户状态 (UI 立即响应)
      _ref.read(currentUserProvider.notifier).setUser(response);

      // 4. 保存到本地账户历史 (用于下次快捷登录)
      // 注意：这里默认 autoLoginEnabled 为 false，需要由 UI 层的 Checkbox 决定是否开启
      await _saveAccountToHistory(response,
          password: password); // 密码可选保存，视安全策略定

      logger.i("✅ [AuthRepo] 登录成功");
      return response;
    } catch (e) {
      logger.e("❌ [AuthRepo] 登录失败", error: e);
      rethrow;
    }
  }

  // ==========================================
  // 2. 注册 (Register)
  // ==========================================

  /// 执行注册
  /// 通常注册成功后需要用户手动登录，或者自动执行一次登录
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarObjectKey,
  }) async {
    try {
      logger.i("📝 [AuthRepo] 开始注册: $username");
      await _api.register(
        username: username,
        email: email,
        password: password,
        avatarUrl: avatarObjectKey,
      );
      logger.i("✅ [AuthRepo] 注册成功");
    } catch (e) {
      logger.e("❌ [AuthRepo] 注册失败", error: e);
      rethrow;
    }
  }

  // ==========================================
  // 3. 自动登录 (Auto Login / Session Restore)
  // ==========================================

  /// 尝试自动登录
  /// 用于 App 启动时调用，如果成功则返回 User，失败返回 null
  Future<AuthResponse?> attemptAutoLogin() async {
    try {
      // 1. 查找是否有开启了"自动登录"的账户
      final account = await _accountService.getAccountForAutoLogin();

      if (account == null) {
        logger.d("🤷‍♂️ [AuthRepo] 未找到自动登录账户");
        return null;
      }

      logger.i("🔄 [AuthRepo] 尝试自动登录: ${account.username}");

      // 2. 恢复 Token 到内存 (此时还未验证有效性)
      await _api.saveToken(account.token);

      // 3. 调用 getSession 验证 Token 是否过期
      final response = await _api.getSession();

      // 4. Token 有效，更新全局状态
      _ref.read(currentUserProvider.notifier).setUser(response);

      // 5. 更新本地账户信息 (比如头像变了、Token 刷新了)
      await _updateAccountHistory(account, response);

      logger.i("✅ [AuthRepo] 自动登录成功");
      return response;
    } catch (e) {
      logger.w("⚠️ [AuthRepo] 自动登录失败 (可能是Token过期): $e");
      // 失败时清除 Token，确保下次干净启动
      await _api.removeToken();
      return null;
    }
  }

  // ==========================================
  // 4. 注销 (Logout)
  // ==========================================

  Future<void> logout() async {
    try {
      logger.i("👋 [AuthRepo] 用户注销");

      // 1. 告知后端 (可选，视后端是否有黑名单机制)
      try {
        await _api.logout();
      } catch (e) {
        // 注销接口报错不应阻断本地清除逻辑
        logger.w("注销接口调用失败 (忽略): $e");
      }

      // 2. 清除本地 Token
      await _api.removeToken();

      // 3. 清除全局用户状态
      _ref.read(currentUserProvider.notifier).clear();

      // 4. (可选) 断开 MQTT
      // 由于 MqttService 监听了 currentUserProvider，这一步通常会自动触发，
      // 但为了保险也可以显式调用 ref.invalidate(mqttServiceProvider);
    } catch (e) {
      logger.e("❌ [AuthRepo] 注销流程异常", error: e);
    }
  }

  // ==========================================
  // 私有辅助方法
  // ==========================================

  Future<void> _saveAccountToHistory(AuthResponse response,
      {String? password}) async {
    // 检查之前的配置 (是否开启了自动登录)
    final existingAccounts = await _accountService.loadSavedAccounts();
    final existing = existingAccounts.firstWhere(
      (acc) => acc.username == response.username,
      orElse: () => SavedAccount(
        username: response.username,
        token: response.token,
        avatarUrl: response.avatarUrl,
        autoLoginEnabled: false, // 默认为 false
      ),
    );

    // 更新信息
    final updated = SavedAccount(
      username: response.username,
      token: response.token,
      avatarUrl: response.avatarUrl,
      autoLoginEnabled: existing.autoLoginEnabled, // 保持之前的设置
    );

    await _accountService.saveOrUpdateAccount(updated);
  }

  Future<void> _updateAccountHistory(
      SavedAccount oldAccount, AuthResponse newResponse) async {
    final updated = SavedAccount(
      username: newResponse.username,
      token: newResponse.token, // 使用最新的 Token
      avatarUrl: newResponse.avatarUrl, // 使用最新的头像
      autoLoginEnabled: oldAccount.autoLoginEnabled, // 保持开启状态
    );
    await _accountService.saveOrUpdateAccount(updated);
  }
}
