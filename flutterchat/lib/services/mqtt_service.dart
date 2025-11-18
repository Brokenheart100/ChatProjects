import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// 定义一个简单的消息数据模型
class ChatMessageEvent {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessageEvent(
      {required this.senderId, required this.text, required this.timestamp});

  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      senderId: json['senderId'],
      text: json['text'],
      timestamp: DateTime.now(), // 简单处理，未来可由服务器提供
    );
  }
}

class MqttService {
  late final MqttServerClient _client;
  final String _userId;

  // 使用 StreamController 来向应用的其他部分广播收到的消息
  final _messageStreamController =
      StreamController<ChatMessageEvent>.broadcast();
  Stream<ChatMessageEvent> get onMessageReceived =>
      _messageStreamController.stream;

  MqttService({required String serverAddress, required String userId})
      : _userId = userId {
    _client = MqttServerClient.withPort(
      serverAddress,
      'flutter_client_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      1883, // MQTT 协议标准端口
    );
    _client.logging(on: kDebugMode); // 只在 Debug 模式下打印详细日志
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.pongCallback = _pong;
  }

  /// 连接到 MQTT Broker
  Future<void> connect() async {
    // 设置最后遗嘱消息，当客户端意外断开时，Broker 会发布此消息
    final willMessage =
        MqttClientPayloadBuilder().addString('{"status": "offline"}').payload;
    // _client.keepAlivePeriod = 60;
    // _client.willTopic = 'users/$_userId/status';
    // _client.willMessage = willMessage;
    // _client.willQos = MqttQos.atLeastOnce;

    try {
      logger.i('MQTT: 正在连接...');
      await _client.connect();
    } catch (e) {
      logger.e('MQTT: 连接异常 - $e');
      disconnect();
    }
  }

  void _onConnected() {
    logger.i('MQTT: 已连接！');
    // 订阅自己的私聊消息主题
    final topic = 'chats/$_userId/messages';
    _client.subscribe(topic, MqttQos.atLeastOnce);

    // 监听所有收到的消息
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      logger.i('MQTT: 收到消息. 主题: ${c[0].topic}, 内容: $payload');

      try {
        final json = jsonDecode(payload);
        final messageEvent = ChatMessageEvent.fromJson(json);
        _messageStreamController.add(messageEvent); // 将解析后的消息放入流中
      } catch (e) {
        logger.e('MQTT: 解析收到的消息失败', error: e);
      }
    });
  }

  void _onDisconnected() {
    logger.w('MQTT: 已断开连接。');
  }

  void _onSubscribed(String topic) {
    logger.i('MQTT: 已成功订阅主题: $topic');
  }

  void _pong() {
    logger.d('MQTT: Ping 响应 (pong) 已收到。');
  }

  /// 发送聊天消息
  void sendChatMessage(String recipientId, String text) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) {
      logger.w('MQTT: 无法发送消息，连接未建立。');
      return;
    }

    final topic = 'chats/$recipientId/messages';
    final builder = MqttClientPayloadBuilder();
    // 构建一个标准的 JSON 消息体
    final payload = jsonEncode({
      'senderId': _userId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    builder.addString(payload);

    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    logger.i('MQTT: 消息已发布到主题: $topic');
  }

  /// 断开连接
  void disconnect() {
    _client.disconnect();
  }

  /// 释放资源
  void dispose() {
    _messageStreamController.close();
  }
}
