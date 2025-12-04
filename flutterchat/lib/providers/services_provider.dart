import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/services/objectbox_service.dart';

// Riverpod 代码生成关联文件，通过 build_runner 生成服务 Provider 的实现代码
part 'services_provider.g.dart';

/// MQTT 系统事件流 Provider
/// 提供 MQTT 服务的系统级事件监听能力（如连接状态变化、系统通知、异常事件等）
/// 依赖 [mqttServiceProvider]，当 MQTT 服务触发系统事件时，通过该流通知订阅者
@riverpod
Stream<SystemEvent> mqttSystemStream(MqttSystemStreamRef ref) {
  // 监听 MQTT 服务实例
  final service = ref.watch(mqttServiceProvider);
  // 返回 MQTT 服务暴露的系统事件流
  return service.onSystemEventReceived;
}

/// 1. 基础核心服务 Provider 组（单例模式）
/// 所有基础服务均设置 keepAlive: true，确保全局单例且不会被 Riverpod 自动销毁
/// 用于提供应用底层核心能力，无需手动管理生命周期

/// API 基础请求客户端 Provider
/// 提供最底层的网络请求能力（如 HTTP 客户端配置、请求拦截等）
/// 所有 API 相关操作的基础依赖，全局单例
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

/// API 业务服务 Provider
/// 封装应用所有后端 API 接口调用（如登录、聊天、用户信息等业务接口）
/// 依赖 [apiClientProvider]，提供面向业务的 API 调用方法
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) => ApiService();

/// 账户业务服务 Provider
/// 封装账户相关核心业务（如登录状态管理、令牌刷新、退出登录等）
/// 处理账户层面的逻辑封装，与 API 服务协作完成账户操作
@Riverpod(keepAlive: true)
AccountService accountService(AccountServiceRef ref) => AccountService();

/// ✅ 新增：ObjectBox 本地数据库服务 Provider
/// 提供本地数据库操作能力（数据存储、查询、更新、删除等）
/// 注意事项：
/// 1. 初始状态抛出未实现错误，因为 ObjectBox 需要在 main.dart 中初始化（依赖原生资源）
/// 2. 需在 main.dart 中通过 ProviderScope.override 覆盖该 Provider 的实现
/// 3. keepAlive: true 确保数据库连接全局复用，避免频繁创建销毁
@Riverpod(keepAlive: true)
ObjectBoxService objectBox(ObjectBoxRef ref) {
  throw UnimplementedError('ObjectBox 必须在 main.dart 中初始化并覆盖该 Provider');
}

/// 2. 全局当前登录用户状态 Provider
/// 采用 StateNotifier 模式，提供用户状态的修改和访问能力
/// keepAlive: true 确保用户状态在应用生命周期内全局共享（除非主动清除）
@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  /// 初始化用户状态为 null（未登录）
  @override
  AuthResponse? build() => null;

  /// 设置当前登录用户信息
  /// [user]：登录成功后返回的用户认证信息（包含 userId、令牌等核心数据）
  void setUser(AuthResponse user) => state = user;

  /// 清除当前用户信息（退出登录时调用）
  /// 调用后状态重置为 null，依赖该状态的服务会自动响应（如 MQTT 断开连接）
  void clear() => state = null;
}

/// 3. MQTT 消息服务 Provider（依赖登录状态）
/// 提供 MQTT 协议的消息收发能力（聊天消息、实时通知等）
/// keepAlive: true 确保 MQTT 连接在登录后持续保持
@Riverpod(keepAlive: true)
MqttService mqttService(MqttServiceRef ref) {
  // 监听当前登录用户状态，必须登录后才能初始化 MQTT 服务
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception("MQTT 服务初始化失败：用户未登录");
  }

  // 从环境变量获取 MQTT 服务器地址，默认值为 localhost（开发环境）
  // 生产环境需通过编译参数配置：--dart-define=MQTT_HOST=xxx.xxx.xxx.xxx
  const mqttServer =
      String.fromEnvironment('MQTT_HOST', defaultValue: 'localhost');

  // 创建 MQTT 服务实例：传入服务器地址和当前用户 ID（作为 MQTT 客户端标识）
  final service = MqttService(serverAddress: mqttServer, userId: user.userId);

  // 初始化时自动连接 MQTT 服务器
  service.connect();

  // 注册销毁回调：当 Provider 被销毁时（如用户退出登录），断开 MQTT 连接并释放资源
  ref.onDispose(() => service.dispose());

  return service;
}

/// 4. MQTT 聊天消息流 Provider
/// 提供 MQTT 服务接收的聊天消息流，方便 UI 层监听实时消息
/// 无需设置 keepAlive：依赖的 [mqttServiceProvider] 已为单例，流会随服务生命周期变化
@riverpod
Stream<ChatMessageEvent> mqttMessageStream(MqttMessageStreamRef ref) {
  // 监听 MQTT 服务实例
  final service = ref.watch(mqttServiceProvider);
  // 返回 MQTT 服务暴露的聊天消息流，UI 层可通过 StreamBuilder 监听并更新界面
  return service.onMessageReceived;
}
