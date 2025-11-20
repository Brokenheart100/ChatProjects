import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_client.dart'; // 引入刚才写的文件
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
  // 1. 核心改动：不再自己 new Dio，而是获取 ApiClient 单例中的 dio
  // 这样就自动拥有了拦截器、BaseUrl 和 SSL 配置
  Dio get _dio => ApiClient().dio;

  // 移除 _tokenKey，因为它现在由 ApiClient 管理

  ApiService(); // 构造函数现在是空的，非常轻量

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
        // 核心改动：调用 ApiClient 来保存 Token
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
      // 拦截器会自动加上 Authorization 头
      final response = await _dio.get('/gateway/auth/session');
      final authResponse = AuthResponse.fromJson(response.data);
      // 刷新 Token
      await ApiClient().saveToken(authResponse.token);
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e, 'getSession');
    }
  }

  Future<void> logout() async {
    // 核心改动：调用 ApiClient 来清除 Token
    await ApiClient().removeToken();
  }

  // --- 聊天/消息相关 ---

  Future<List<ChatMessage>> getMessageHistory(String conversationId,
      {required String currentUserId}) async {
    try {
      // 注意：queryParameters 会自动拼接到 url 后面
      final response = await _dio.get(
        '/gateway/conversations/$conversationId/messages',
        queryParameters: {'limit': 50},
      );

      final List<dynamic> data = response.data;
      return data.map((json) {
        final senderId = json['senderId'].toString();
        return ChatMessage(
          isMe: senderId == currentUserId,
          sender: senderId,
          text: json['content'],
          // contentType: 1 代表图片，0 代表文本
          contentType: json['contentType'] ?? 0,
          avatar: '', // 暂时留空，由 UI 层处理缓存
        );
      }).toList();
    } on DioException catch (e) {
      // 如果是 404 可能是新会话，返回空列表，不要报错
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

  // --- 文件上传相关 (重点修改) ---

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
    // 1. 获取上传链接
    final uploadInfo = await getUploadUrl(file.name);

    // 2. 执行上传
    // 注意：这里不能用 _dio！因为 _dio 有 BaseUrl 还有 Token 拦截器。
    // 上传到 MinIO 是一个完整的 Presigned URL，且不需要（甚至不能带）后端 API 的 Token。
    await _uploadToMinioRaw(uploadInfo.uploadUrl, file);

    return uploadInfo.objectKey;
  }

  Future<void> _uploadToMinioRaw(String uploadUrl, XFile file) async {
    try {
      final fileBytes = await file.readAsBytes();

      // 创建一个“纯净”的 Dio 实例，专门用于这次上传
      final cleanDio = Dio();

      await cleanDio.put(
        uploadUrl,
        data: Stream.fromIterable(fileBytes.map((e) => [e])), // 流式上传
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileBytes.length,
            // 根据文件后缀判断类型，这里暂写死 jpeg，实际可以用 lookupMimeType
            Headers.contentTypeHeader: 'image/jpeg',
          },
        ),
      );
      logger.i('MinIO Upload Success');
    } on DioException catch (e) {
      logger.e('MinIO Upload Failed', error: e);
      throw '文件上传失败';
    }
  }

  // --- 好友/搜索相关 ---

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

  Future<void> sendFriendRequest(String recipientId) async {
    try {
      await _dio.post('/gateway/friends/requests',
          data: {'recipientId': recipientId});
    } on DioException catch (e) {
      throw _handleError(e, 'sendFriendRequest');
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
      return 0; // 出错默认 0
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

  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/reject');
  }

  // --- 辅助方法 ---

  // 移除 saveToken，改为调用 ApiClient().saveToken
  // 这里的 saveToken 可以作为一个 wrapper 方便旧代码调用
  Future<void> saveToken(String token) async {
    await ApiClient().saveToken(token);
  }

  // 为了兼容旧代码，保留这个 Helper
  String getFullAvatarUrl(String? objectKey) {
    if (objectKey == null || objectKey.isEmpty) return '';
    if (objectKey.startsWith('http')) return objectKey;

    // 注意：这里的 MinIO 地址如果和 API 不一样，需要单独配置
    // 开发环境通常 localhost:9000
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
