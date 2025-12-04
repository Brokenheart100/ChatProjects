import 'package:dio/dio.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/logger_service.dart';

mixin ChatApi on ApiBase {
  /// 获取会话列表
  Future<List<Conversation>> getConversations(
      {required String currentUserId}) async {
    try {
      final response = await dio.get('/gateway/conversations');
      final List<dynamic> data = response.data;

      return data.map((json) {
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
        return ChatMessage(
          id: 0,
          uuid: json['id']?.toString() ?? '',
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
  Future<String> sendMessage(String conversationId, String content,
      {int contentType = 0, String? recipientId}) async {
    try {
      final response = await dio.post(
        '/gateway/messages',
        data: {
          'conversationId': conversationId,
          'content': content,
          'contentType': contentType,
          'recipientId': recipientId,
        },
      );

      // ❌ 错误写法 (可能你写成了这样)：
      // return response.data; // 这会返回 Map

      // ✅ 正确写法：提取 ID
      final realId = response.data['realConversationId']?.toString();

      // 返回 ID 字符串
      return realId ?? conversationId;
    } on DioException catch (e) {
      throw handleError(e, 'sendMessage');
    }
  }

  /// 创建群聊
  Future<void> createGroup(
      String id, String groupName, List<String> memberIds) async {
    try {
      await dio.post('/gateway/groups', data: {
        'id': id,
        'groupName': groupName,
        'memberIds': memberIds,
      });
      logger.i("✅ API调用成功: 群聊已创建 (ID: $id)");
    } on DioException catch (e) {
      throw handleError(e, 'createGroup');
    }
  }
}
