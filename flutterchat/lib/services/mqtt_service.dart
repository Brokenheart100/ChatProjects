import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutterchat/services/logger_service.dart';

// 1. 修改 Event 类
class ChatMessageEvent {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String conversationId; // <--- 新增字段

  ChatMessageEvent({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.conversationId, // <---
  });

  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      conversationId:
          json['conversationId']?.toString() ?? '', // <--- 解析后端传回的 ID
    );
  }
}

class MqttService {
  late final MqttServerClient _client;
  final String _userId;

  // --- 关键点：创建一个广播流控制器 ---
  final _messageStreamController =
      StreamController<ChatMessageEvent>.broadcast();

  // --- 关键点：暴露流给外部 (ChatBloc) 监听 ---
  Stream<ChatMessageEvent> get onMessageReceived =>
      _messageStreamController.stream;

  MqttService({required String serverAddress, required String userId})
      : _userId = userId {
    // 注意：端口通常是 1883 (TCP) 或 8083/8084 (Websocket)
    // 如果是 Flutter Web 必须用 Websocket，App 可以用 TCP
    _client = MqttServerClient(serverAddress, 'flutter_client_$_userId');
    _client.port = 1883;
    _client.logging(on: kDebugMode);
    _client.onConnected = _onConnected;
  }

  Future<void> connect() async {
    try {
      await _client.connect();
    } catch (e) {
      logger.e('MQTT 连接失败: $e');
    }
  }

  void _onConnected() {
    logger.i('MQTT 已连接');
    // 订阅自己的消息主题，或者具体的会话主题
    // 假设后端推送的主题是 "users/{userId}/messages" 或 "chats/{conversationId}"
    // 这里我们订阅所有发给这个用户的消息
    _client.subscribe('users/$_userId/messages', MqttQos.atLeastOnce);
    _client.subscribe('chats/+/messages', MqttQos.atLeastOnce);
    // 监听消息
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final json = jsonDecode(pt);
        // --- 关键点：解析并添加到流中 ---
        final event = ChatMessageEvent.fromJson(json);
        _messageStreamController.add(event);
      } catch (e) {
        logger.e('解析 MQTT 消息失败: $pt');
      }
    });
  }

  void dispose() {
    _messageStreamController.close();
    _client.disconnect();
  }
}
