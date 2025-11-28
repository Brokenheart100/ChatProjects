import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/services/objectbox_service.dart';

part 'services_provider.g.dart';

// 新增 Provider
@riverpod
Stream<SystemEvent> mqttSystemStream(MqttSystemStreamRef ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.onSystemEventReceived;
}

// 1. 基础服务单例
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) => ApiService();

@Riverpod(keepAlive: true)
AccountService accountService(AccountServiceRef ref) => AccountService();

// ✅ 新增：ObjectBox 服务 Provider
// 初始抛出异常，因为我们会在 main.dart 中初始化并覆盖它
@Riverpod(keepAlive: true)
ObjectBoxService objectBox(ObjectBoxRef ref) {
  throw UnimplementedError('ObjectBox must be initialized in main.dart');
}

// 2. 当前登录用户 (全局状态)
@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  AuthResponse? build() => null;

  void setUser(AuthResponse user) => state = user;
  void clear() => state = null;
}

// 3. MQTT 服务 (依赖 CurrentUser)
@Riverpod(keepAlive: true)
MqttService mqttService(MqttServiceRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception("未登录");

  const mqttServer =
      String.fromEnvironment('MQTT_HOST', defaultValue: 'localhost');
  final service = MqttService(serverAddress: mqttServer, userId: user.userId);
  service.connect();

  ref.onDispose(() => service.dispose());
  return service;
}

// 4. MQTT 消息流 (方便监听)
@riverpod
Stream<ChatMessageEvent> mqttMessageStream(MqttMessageStreamRef ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.onMessageReceived;
}
