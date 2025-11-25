import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart'; // 确保引入了 Conversation
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/logger_service.dart';

/// 文件上传信息模型
class UploadInfo {
  final String uploadUrl;
  final String objectKey;
  UploadInfo({required this.uploadUrl, required this.objectKey});
  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    return UploadInfo(
      uploadUrl: json['uploadUrl'],
      objectKey: json['objectKey'],
    );
  }
}

class ApiService {
  // 获取单例 ApiClient 中的 dio 实例
  Dio get _dio => ApiClient().dio;

  // 构造函数
  ApiService();

// 创建群聊
  Future<void> createGroup(String groupName, List<String> memberIds) async {
    try {
      await _dio.post('/gateway/groups', data: {
        'groupName': groupName,
        'memberIds': memberIds,
      });
      logger.i("✅ 群聊创建成功");
    } on DioException catch (e) {
      throw _handleError(e, 'createGroup');
    }
  }
  // --- 认证相关 ---

  Future<AuthResponse> login(
      {required String username, required String password}) async {
    try {
      final response = await _dio.post(
        '/gateway/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        await ApiClient().saveToken(authResponse.token);
        return authResponse;
      } else {
        throw '登录失败，服务器未返回数据';
      }
    } on DioException catch (e) {
      throw _handleError(e, 'login');
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      await _dio.post(
        '/gateway/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'avatarUrl': avatarUrl,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e, 'register');
    }
  }

  Future<AuthResponse> getSession() async {
    try {
      final response = await _dio.get('/gateway/auth/session');
      final authResponse = AuthResponse.fromJson(response.data);
      await ApiClient().saveToken(authResponse.token);
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e, 'getSession');
    }
  }

  Future<void> logout() async {
    await ApiClient().removeToken();
  }

  // --- 会话列表 (核心：后端聚合模式) ---

  Future<List<Conversation>> getConversations(
      {required String currentUserId}) async {
    try {
      final response = await _dio.get('/gateway/conversations');
      final List<dynamic> data = response.data;
      // 后端已经聚合了 Name 和 Avatar，前端直接转换即可，速度极快
      return data.map((json) {
        final timeStr = json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'])
                .toLocal()
                .toString()
                .substring(11, 16)
            : '';
        final isGroup = json['type'] == 1;

        return Conversation(
          id: json['id'].toString(),
          recipientId: json['recipientId'] ?? '',
          // 直接使用后端返回的名字，如果没有则显示"未知"
          name: json['name'] ?? '未知用户',
          // 拼接头像 URL
          avatar: getFullAvatarUrl(json['avatar']),
          lastMessage: json['lastMessage'] ?? '',
          time: timeStr,
          isGroup: isGroup,
          messages: [],
        );
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e, 'getConversations');
    }
  }

  // --- 历史消息 ---

  Future<List<ChatMessage>> getMessageHistory(String conversationId,
      {required String currentUserId}) async {
    try {
      final response = await _dio.get(
        '/gateway/conversations/$conversationId/messages',
        queryParameters: {'limit': 50},
      );

      final List<dynamic> data = response.data;

      // 调试日志
      if (data.isNotEmpty) {
        // logger.d("🔍 历史消息示例: ${data[0]}");
      }

      return data.map((json) {
        final senderId = json['senderId'].toString();
        return ChatMessage(
          isMe:
              senderId.toLowerCase() == currentUserId.toLowerCase(), // 忽略大小写比较
          sender: senderId,
          text: json['content'],
          contentType: json['contentType'] ?? 0,
          avatar: '', // 详情页头像暂留空，可由 UI 根据 senderId 统一处理
        );
      }).toList();
    } on DioException catch (e) {
      // 404/403 视为新会话，返回空列表
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return [];
      }
      throw _handleError(e, 'getMessageHistory');
    }
  }

  Future<void> sendMessage(String conversationId, String content,
      {int contentType = 0, String? recipientId}) async {
    try {
      await _dio.post(
        '/gateway/messages',
        data: {
          'conversationId': conversationId,
          'content': content,
          'contentType': contentType,
          'recipientId': recipientId,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e, 'sendMessage');
    }
  }

  // --- 文件上传 ---

  Future<UploadInfo> getUploadUrl(String fileName) async {
    try {
      final response = await _dio.get(
        '/gateway/files/generate-upload-url',
        queryParameters: {'fileName': fileName},
      );
      return UploadInfo.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'getUploadUrl');
    }
  }

  Future<String> uploadFileAndGetObjectKey(XFile file) async {
    final uploadInfo = await getUploadUrl(file.name);
    await _uploadToMinioRaw(uploadInfo.uploadUrl, file);
    return uploadInfo.objectKey;
  }

  Future<void> _uploadToMinioRaw(String uploadUrl, XFile file) async {
    try {
      final fileBytes = await file.readAsBytes();
      // 使用纯净 Dio 实例上传，避免带入 Token
      final cleanDio = Dio();
      await cleanDio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileBytes.length,
            Headers.contentTypeHeader:
                'image/jpeg', // 简单处理，生产环境应用 lookupMimeType
          },
        ),
      );
      logger.i('MinIO Upload Success');
    } on DioException catch (e) {
      logger.e('MinIO Upload Failed', error: e);
      throw '文件上传失败';
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/gateway/search/users',
        queryParameters: {'query': query},
      );
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'searchUsers');
    }
  }

  Future<List<UserSearchResult>> getFriends() async {
    try {
      final response = await _dio.get('/gateway/friends');
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'getFriends');
    }
  }

  Future<int> getPendingFriendRequestsCount() async {
    try {
      final response =
          await _dio.get('/gateway/friends/requests/pending/count');
      return response.data['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response = await _dio.get('/gateway/friends/requests/pending');
      return (response.data as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
    await _dio
        .post('/gateway/friends/requests', data: {'recipientId': recipientId});
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/reject');
  }

  // --- 辅助方法 ---

  Future<void> saveToken(String token) async {
    await ApiClient().saveToken(token);
  }

  String getFullAvatarUrl(String? objectKey) {
    if (objectKey == null || objectKey.isEmpty) return '';
    if (objectKey.startsWith('http')) return objectKey;
    // 注意：这里硬编码了 localhost，真机调试需改为 IP (如 10.0.2.2) 或配置项
    const minioUrl = 'http://localhost:9000/avatars';
    return '$minioUrl/$objectKey';
  }

  String _handleError(DioException e, String context) {
    logger.e('Error in $context: ${e.message}', error: e);
    if (e.response?.data is String) {
      return e.response?.data;
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return '连接超时，请检查网络';
    }
    return '操作失败 (${e.response?.statusCode})';
  }
}
