import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:uuid/uuid.dart';

// 1. 修改 Event 类
class ChatMessageEvent {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String conversationId;
  final String messageId; // 新增：记录后端的 MessageId

  ChatMessageEvent({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.conversationId,
    required this.messageId,
  });

  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      conversationId: json['conversationId']?.toString() ?? '',
      // 尝试获取后端 ID，如果没有则生成一个临时 UUID (健壮性处理)
      messageId: json['messageId']?.toString() ??
          json['id']?.toString() ??
          const Uuid().v4(),
    );
  }

  // ✅ 核心修复：适配 ObjectBox 的 ChatMessage 构造函数
  ChatMessage toMessage(String currentUserId) {
    return ChatMessage(
      id: 0, // ObjectBox 本地 ID，插入时自动生成
      uuid: messageId, // 业务 ID
      conversationId: conversationId,
      senderId: senderId, // 使用 senderId 替代 sender
      text: text,
      isMe: senderId == currentUserId,
      avatar: '', // 暂时留空，由 UI/Provider 层处理头像
      contentType: 0, // 默认为文本
      sentAt: timestamp,
      status: 1, // 接收到的消息默认为成功
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
