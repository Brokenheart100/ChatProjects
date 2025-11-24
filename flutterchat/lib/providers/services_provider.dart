import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:flutterchat/models/auth_response.dart';

part 'services_provider.g.dart';

// 1. 基础服务单例
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) => ApiService();

@Riverpod(keepAlive: true)
AccountService accountService(AccountServiceRef ref) => AccountService();

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
// ✅ 核心修复：函数名改为 mqttMessageStream，对应 mqttMessageStreamProvider
@riverpod
Stream<ChatMessageEvent> mqttMessageStream(MqttMessageStreamRef ref) {
  final service = ref.watch(mqttServiceProvider);
  return service.onMessageReceived;
}
