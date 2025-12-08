import 'package:dio/dio.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/logger_service.dart';

class SendMessageResponse {
  final String realConversationId;
  final String backendMessageId; // 后端生成的 Snowflake ID

  SendMessageResponse({
    required this.realConversationId,
    required this.backendMessageId,
  });
}

mixin ChatApi on ApiBase {
  /// 获取会话列表
  Future<List<Conversation>> getConversations(
      {required String currentUserId}) async {
    try {
      final response = await dio.get('/gateway/conversations');
      final List<dynamic> data = response.data;

      return data.map((json) {
        logger.d(
            "🔍 [API Debug] ID: ${json['id']}, Avatar: ${json['avatar']}"); // 打印看看后端返了什么
        return Conversation(
          id: 0,
          uuid: json['id'].toString(),
          recipientId: json['recipientId'] ?? '',
          name: json['name'] ?? '未知',
          avatar: getFullAvatarUrl(json['avatar']),
          lastMessage: json['lastMessage'] ?? '',
          lastMessageAt: json['lastMessageAt'] != null
              ? DateTime.parse(json['lastMessageAt'])
              : DateTime.now(),
          isGroup: json['type'] == 1,
          unreadCount: json['unreadCount'] ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw handleError(e, 'getConversations');
    }
  }

  /// 获取历史消息
  Future<List<ChatMessage>> getMessageHistory(String conversationId,
      {required String currentUserId}) async {
    try {
      final response = await dio.get(
        '/gateway/conversations/$conversationId/messages',
        queryParameters: {'limit': 50},
      );

      final List<dynamic> data = response.data;
      return data.map((json) {
        final senderId = json['senderId'].toString();
        final backendId = json['id'].toString();
        final clientMsgId = json['clientMessageId']?.toString();

        return ChatMessage(
          id: 0,
          uuid: backendId,
          // uuid: json['id']?.toString() ?? '',
          conversationId: conversationId,
          senderId: senderId,
          text: json['content'],
          contentType: json['contentType'] ?? 0,
          isMe: senderId.toLowerCase() == currentUserId.toLowerCase(),
          avatar: '',
          sentAt: json['sentAt'] != null
              ? DateTime.parse(json['sentAt'])
              : DateTime.now(),
          status: 1,
          clientMessageId: json['clientMessageId']?.toString(),
        );
      }).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return [];
      }
      throw handleError(e, 'getMessageHistory');
    }
  }

  /// ✅ 核心修复：发送消息
  /// 返回值是后端真实的 ConversationId (可能与前端生成的不同)
  Future<SendMessageResponse> sendMessage(
    String conversationId,
    String content, {
    int contentType = 0,
    String? recipientId,
    required String localId, // 👈 新增：必须传入前端生成的 UUID
  }) async {
    try {
      final response = await dio.post(
        '/gateway/messages',
        data: {
          'conversationId': conversationId,
          'content': content,
          'contentType': contentType,
          'recipientId': recipientId,
          'localId': localId, // 👈 传给后端存入 ClientMessageId 字段
        },
      );

      final data = response.data;

      // 解析后端返回的数据
      // C# Controller 返回结构: { "Message": { "id": 123... }, "RealConversationId": "..." }
      final realId = data['realConversationId']?.toString() ?? conversationId;
      final msgId = data['message']['id'].toString(); // 👈 拿到后端的 Snowflake ID

      return SendMessageResponse(
        realConversationId: realId,
        backendMessageId: msgId,
      );
    } on DioException catch (e) {
      throw handleError(e, 'sendMessage');
    }
  }
}
