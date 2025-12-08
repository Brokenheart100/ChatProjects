import 'package:flutterchat/models/auth_response.dart'; // 导入认证响应模型，包含登录/注册成功后的用户信息
import 'package:flutterchat/models/saved_account.dart'; // 导入本地保存的账户模型
import 'package:flutterchat/providers/services_provider.dart'; // 导入服务提供者，用于依赖注入
import 'package:flutterchat/services/account_service.dart'; // 导入账户服务，负责本地账户的增删改查
import 'package:flutterchat/services/api_service.dart'; // 导入API服务，负责与后端交互
import 'package:flutterchat/services/logger_service.dart'; // 导入日志服务，用于记录操作日志
import 'package:riverpod_annotation/riverpod_annotation.dart'; // 导入Riverpod注解，用于生成Provider代码

part 'auth_repository.g.dart'; // Riverpod代码生成文件，由build_runner自动生成

// 定义认证仓库Provider
// keepAlive: true 确保AuthRepository为全局单例，因为认证状态是App的核心，需持久化存在
@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    api: ref.watch(apiServiceProvider), // 注入API服务
    accountService: ref.watch(accountServiceProvider), // 注入账户服务
    ref: ref, // 注入Provider引用，用于读写其他Provider状态
  );
}

/// 认证仓库类，封装所有与用户认证相关的业务逻辑（登录、注册、自动登录、注销等）
class AuthRepository {
  final ApiService _api; // API服务实例，用于调用后端接口
  final AccountService _accountService; // 账户服务实例，用于管理本地保存的账户
  final AuthRepositoryRef _ref; // Provider引用，用于读写全局状态

  /// 构造函数，通过依赖注入初始化服务
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

  /// 执行用户登录流程
  ///
  /// 参数：
  /// - username：用户名
  /// - password：密码
  ///
  /// 返回值：
  /// - 登录成功返回AuthResponse对象（包含用户信息和Token）
  /// - 登录失败抛出异常，由上层处理
  ///
  /// 登录流程：
  /// 1. 调用后端登录接口
  /// 2. 持久化保存Token（确保后续API调用能自动带上Token）
  /// 3. 更新全局用户状态（触发UI刷新）
  /// 4. 保存账户到本地历史（用于快捷登录和自动登录）
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      logger.i("🔐 [AuthRepo] 开始登录: $username"); // 记录登录开始日志

      // 1. 调用后端登录API
      final response = await _api.login(username: username, password: password);

      // 2. 持久化Token到本地（SharedPreferences），确保后续API请求能自动携带Token
      await _api.saveToken(response.token);

      // 3. 更新全局用户状态（通过Riverpod的currentUserProvider），触发UI立即响应
      _ref.read(currentUserProvider.notifier).setUser(response);

      // 4. 保存账户到本地历史，密码可选保存（视安全策略而定）
      // 注意：autoLoginEnabled默认为false，需由UI层的Checkbox决定是否开启
      await _saveAccountToHistory(response, password: password);

      logger.i("✅ [AuthRepo] 登录成功"); // 记录登录成功日志
      return response;
    } catch (e) {
      logger.e("❌ [AuthRepo] 登录失败", error: e); // 记录登录失败日志及异常信息
      rethrow; // 重新抛出异常，让上层组件处理（如显示错误提示）
    }
  }

  // ==========================================
  // 2. 注册 (Register)
  // ==========================================

  /// 执行用户注册流程
  ///
  /// 参数：
  /// - username：用户名
  /// - email：邮箱
  /// - password：密码
  /// - avatarObjectKey：头像对象存储键（可选，用于上传头像）
  ///
  /// 注册流程：
  /// 1. 调用后端注册接口
  /// 2. 注册成功后通常需要用户手动登录，或自动执行一次登录（本实现为手动登录）
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarObjectKey,
  }) async {
    try {
      logger.i("📝 [AuthRepo] 开始注册: $username"); // 记录注册开始日志

      // 调用后端注册API，avatarUrl传入对象存储键（后端会处理为完整URL）
      await _api.register(
        username: username,
        email: email,
        password: password,
        avatarUrl: avatarObjectKey,
      );

      logger.i("✅ [AuthRepo] 注册成功"); // 记录注册成功日志
    } catch (e) {
      logger.e("❌ [AuthRepo] 注册失败", error: e); // 记录注册失败日志及异常信息
      rethrow; // 重新抛出异常，让上层组件处理
    }
  }

  // ==========================================
  // 3. 自动登录 (Auto Login / Session Restore)
  // ==========================================

  /// 尝试自动登录，用于App启动时恢复用户会话
  ///
  /// 返回值：
  /// - 自动登录成功返回AuthResponse对象
  /// - 自动登录失败返回null（无自动登录账户或Token过期）
  ///
  /// 自动登录流程：
  /// 1. 查找本地开启了"自动登录"的账户
  /// 2. 恢复Token到内存
  /// 3. 调用getSession验证Token是否有效
  /// 4. Token有效则更新全局状态，无效则清除Token
  Future<AuthResponse?> attemptAutoLogin() async {
    try {
      // 1. 从本地查找开启了自动登录的账户
      final account = await _accountService.getAccountForAutoLogin();

      if (account == null) {
        logger.d("🤷‍♂️ [AuthRepo] 未找到自动登录账户"); // 无自动登录账户，返回null
        return null;
      }

      logger.i("🔄 [AuthRepo] 尝试自动登录: ${account.username}"); // 记录自动登录开始日志

      // 2. 将本地保存的Token恢复到API服务（此时Token尚未验证有效性）
      await _api.saveToken(account.token);

      // 3. 调用getSession接口验证Token是否过期/有效
      final response = await _api.getSession();

      // 4. Token有效，更新全局用户状态
      _ref.read(currentUserProvider.notifier).setUser(response);

      // 5. 更新本地账户信息（如头像、Token可能已刷新）
      await _updateAccountHistory(account, response);

      logger.i("✅ [AuthRepo] 自动登录成功"); // 记录自动登录成功日志
      return response;
    } catch (e) {
      logger.w("⚠️ [AuthRepo] 自动登录失败 (可能是Token过期): $e"); // 记录自动登录失败日志

      // 自动登录失败时，清除无效Token，确保下次启动时重新登录
      await _api.removeToken();
      return null;
    }
  }

  // ==========================================
  // 4. 注销 (Logout)
  // ==========================================

  /// 执行用户注销流程
  ///
  /// 注销流程：
  /// 1. 调用后端注销接口（可选，视后端是否有Token黑名单机制）
  /// 2. 清除本地Token
  /// 3. 清除全局用户状态
  /// 4. （可选）断开MQTT连接（通常由MQTT服务监听currentUserProvider自动处理）
  Future<void> logout() async {
    try {
      logger.i("👋 [AuthRepo] 用户注销"); // 记录注销开始日志

      // 1. 调用后端注销接口（可选，失败不阻断本地清除逻辑）
      try {
        await _api.logout();
      } catch (e) {
        // 后端注销接口失败不影响本地注销流程，仅记录警告日志
        logger.w("注销接口调用失败 (忽略): $e");
      }

      // 2. 清除本地保存的Token
      await _api.removeToken();

      // 3. 清除全局用户状态，触发UI切换到登录页
      _ref.read(currentUserProvider.notifier).clear();

      // 4. （可选）显式断开MQTT连接
      // 由于MqttService通常监听currentUserProvider，状态清除后会自动断开，此处可省略
      // _ref.invalidate(mqttServiceProvider);
    } catch (e) {
      logger.e("❌ [AuthRepo] 注销流程异常", error: e); // 记录注销异常日志
    }
  }

  // ==========================================
  // 私有辅助方法
  // ==========================================

  /// 将登录成功的账户保存到本地历史记录
  ///
  /// 参数：
  /// - response：登录成功的认证响应
  /// - password：密码（可选，视安全策略而定）
  ///
  /// 逻辑：
  /// 1. 加载现有账户历史
  /// 2. 查找该账户之前的配置（主要是autoLoginEnabled状态）
  /// 3. 创建更新后的账户对象，更新lastLoginAt时间
  /// 4. 保存到本地
  Future<void> _saveAccountToHistory(AuthResponse response,
      {String? password}) async {
    final existingAccounts = await _accountService.loadSavedAccounts();

    // 查找该账户之前的配置，保留autoLoginEnabled状态
    bool autoLogin = false;
    try {
      final old =
          existingAccounts.firstWhere((a) => a.username == response.username);
      autoLogin = old.autoLoginEnabled;
    } catch (_) {
      // 首次登录，autoLogin默认为false
    }

    // 创建更新后的账户对象，更新登录时间
    final updated = SavedAccount(
      username: response.username,
      token: response.token,
      avatarUrl: response.avatarUrl,
      autoLoginEnabled: autoLogin,
      lastLoginAt: DateTime.now(), // ✅ 关键：更新为当前登录时间，用于排序
    );

    // 保存到本地账户历史
    await _accountService.saveOrUpdateAccount(updated);
  }

  /// 更新本地账户历史记录
  ///
  /// 参数：
  /// - oldAccount：旧的账户信息（包含之前的配置，如autoLoginEnabled）
  /// - newResponse：新的认证响应（包含最新的用户信息和Token）
  ///
  /// 逻辑：
  /// 使用最新的用户信息和Token，保持原有的autoLoginEnabled状态
  Future<void> _updateAccountHistory(
      SavedAccount oldAccount, AuthResponse newResponse) async {
    final updated = SavedAccount(
      username: newResponse.username,
      token: newResponse.token, // 使用最新的Token
      avatarUrl: newResponse.avatarUrl, // 使用最新的头像
      autoLoginEnabled: oldAccount.autoLoginEnabled, // 保持原有的自动登录状态
    );
    await _accountService.saveOrUpdateAccount(updated);
  }

  /// 快速登录（点击历史头像登录）
  ///
  /// 参数：
  /// - account：本地保存的账户对象
  ///
  /// 返回值：
  /// - 快速登录成功返回AuthResponse对象
  /// - 快速登录失败抛出异常（如Token过期）
  ///
  /// 快速登录流程：
  /// 1. 恢复Token到内存
  /// 2. 调用getSession验证Token有效性
  /// 3. Token有效则更新全局状态，无效则抛出异常
  /// 4. 刷新本地账户的活跃时间
  Future<AuthResponse> quickLogin(SavedAccount account) async {
    try {
      logger.i("⚡ [AuthRepo] 尝试快速登录: ${account.username}"); // 记录快速登录开始日志

      // 1. 恢复本地保存的Token到API服务
      await _api.saveToken(account.token);

      // 2. 验证Token有效性，若过期会抛出401异常
      final response = await _api.getSession();

      // 3. 更新全局用户状态
      _ref.read(currentUserProvider.notifier).setUser(response);

      // 4. 刷新本地账户的活跃时间（lastLoginAt）
      await _saveAccountToHistory(response);

      logger.i("✅ [AuthRepo] 快速登录成功"); // 记录快速登录成功日志
      return response;
    } catch (e) {
      logger.w("⚠️ [AuthRepo] 快速登录失败 (Token已过期): $e"); // 记录快速登录失败日志

      // 清除无效Token
      await _api.removeToken();
      rethrow; // 抛出异常，让UI层提示用户输入密码重新登录
    }
  }
}
