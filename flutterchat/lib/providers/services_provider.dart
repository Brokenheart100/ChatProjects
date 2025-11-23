import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

// 这是 Riverpod 注解处理器生成代码的部分，
// 运行 `build_runner` 后会生成 `services_provider.g.dart` 文件，
// 其中包含了各个 provider 的具体实现（如 `apiClientProvider`）。
part 'services_provider.g.dart';

/// 1. API 客户端 Provider (全局单例)
///
/// - `keepAlive: true`: 这是一个关键配置。它告诉 Riverpod 这个 provider 创建的实例
///   应该被永久保存，即使没有任何组件在监听它。这对于像 `ApiClient` 这样需要
///   保持网络连接池或状态的服务来说非常重要。
/// - 作用: 提供一个应用级别的 `ApiClient` 单例。`ApiClient` 通常是对底层 HTTP
///   请求（如使用 Dio 或 http 包）的封装，负责处理 base URL、拦截器、认证令牌等。
/// - 为什么用 Provider: 通过 Riverpod 提供，可以轻松地在应用的任何地方注入和使用，
///   同时也便于在测试中进行模拟（mock）。
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

/// 2. API 服务 Provider (业务逻辑层)
///
/// - 依赖: 虽然这个 provider 的代码看起来没有直接依赖 `apiClientProvider`，
///   但在实际应用中，`ApiService` 内部通常会通过 `ref.watch(apiClientProvider)`
///   来获取 `ApiClient` 实例。
/// - 作用: `ApiService` 是业务逻辑的封装层。它调用 `ApiClient` 提供的底层接口，
///   并将原始的 HTTP 响应转换为应用所需的模型对象（如 `User`、`Message`），
///   同时处理错误和业务逻辑。
/// - `keepAlive: true`: 同样设置为永久保存，因为业务服务通常也是无状态的，
///   并且需要在整个应用生命周期中随时可用。
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

/// 3. 当前登录用户 State Notifier Provider
///
/// - 这是一个 `Notifier` provider，用于管理具有复杂状态逻辑的状态。
///   它比简单的 `StateProvider` 更适合用于需要通过方法来修改状态的场景。
/// - 作用: 全局共享和管理当前登录用户的信息。这是一个非常核心的应用状态。
/// - `build()`: 初始化状态为 `null`，表示初始时用户未登录。
/// - `setUser(AuthResponse user)`: 一个公开的方法，用于在用户登录成功后更新状态。
/// - `clear()`: 一个公开的方法，用于在用户登出时清空状态。
/// - 为什么用 Notifier: 它将状态的修改逻辑封装在自身内部，使得状态变化可预测、
///   可追踪，并且可以包含更复杂的逻辑（例如，在设置用户时同时保存 token）。
@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  AuthResponse? build() => null;

  void setUser(AuthResponse user) => state = user;
  void clear() => state = null;
}

/// 4. MQTT 服务 Provider (后台长连接服务)
///
/// - 这是一个非常典型的“依赖其他状态来初始化服务”的场景。
/// - `ref.watch(currentUserProvider)`: 这是 Riverpod 依赖管理的核心。
///   它声明了当前 provider 依赖于 `currentUserProvider` 的状态。
///   - 如果 `currentUserProvider` 的状态发生变化（例如，用户登录或登出），
///     这个 provider 会被重新计算（recomputed）。
///   - 在这里，我们用它来获取登录用户的 `userId`，这是 MQTT 连接所必需的。
/// - 初始化逻辑:
///   - 如果 `user` 为 `null`（用户未登录），则抛出异常。这可以防止在未登录状态下
///     错误地初始化 MQTT 服务。
///   - 从环境变量中获取 MQTT 服务器地址，这是一种灵活的配置方式，便于不同环境
///     （开发、测试、生产）使用不同的配置。
///   - 创建 `MqttService` 实例并调用 `connect()` 方法建立连接。
/// - `ref.onDispose`: 这是 Riverpod 强大的生命周期管理功能。
///   它注册了一个回调，当这个 provider 被销毁时（例如，因为用户登出导致依赖
///   `currentUserProvider` 变为 `null`，从而使这个 provider 失效），
///   `service.dispose()` 方法会被自动调用，确保 MQTT 连接被正确断开，
///   释放资源。
/// - `keepAlive: true`: 确保 MQTT 服务在后台持续运行，即使没有 UI 组件直接监听它。
@Riverpod(keepAlive: true)
MqttService mqttService(MqttServiceRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception("用户未登录，无法初始化 MQTT");
  }

  // 获取环境变量 (Aspire 注入的地址)
  const mqttServer =
      String.fromEnvironment('MQTT_HOST', defaultValue: 'localhost');

  final service = MqttService(serverAddress: mqttServer, userId: user.userId);
  service.connect();

  // 当 Provider 被销毁时（比如登出），自动断开连接
  ref.onDispose(() => service.dispose());

  return service;
}

/// 5. MQTT 消息流 Provider (数据访问层)
///
/// - 这是一个派生 provider，它本身不创建新的服务，而是从 `mqttServiceProvider`
///   获取服务实例，并暴露其内部的 `Stream`。
/// - 作用: 为应用的其他部分（特别是 UI 组件）提供一个方便的、可监听的 MQTT 消息源。
///   UI 组件可以通过 `ref.watch(mqttMessageStreamProvider)` 来监听新消息，
///   并在消息到达时自动重建。
/// - 为什么这样设计: 它遵循了“关注点分离”原则。`mqttServiceProvider` 负责管理
///   MQTT 连接的生命周期，而 `mqttMessageStreamProvider` 则专门提供数据流。
///   这使得代码更清晰，也更易于测试和复用。
@riverpod
Stream<ChatMessageEvent> mqttMessageStream(MqttMessageStreamRef ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.onMessageReceived;
}
