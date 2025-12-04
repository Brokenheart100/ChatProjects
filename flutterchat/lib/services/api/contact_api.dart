import 'package:dio/dio.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/logger_service.dart';

mixin ContactApi on ApiBase {
  Future<Map<String, bool>> getOnlineStatusBatch(List<String> userIds) async {
    try {
      // 调用后端接口 (注意：需要确保 Gateway 配置了 /gateway/status 的转发)
      final response = await dio.post(
        '/gateway/status/batch-check',
        data: userIds,
      );

      // 后端返回的是 JSON 对象 { "userId1": true, "userId2": false }
      // 我们需要将其转换为 Dart 的 Map<String, bool>
      final Map<String, dynamic> data = response.data;
      return data.map((key, value) => MapEntry(key, value as bool));
    } on DioException catch (e) {
      // 获取状态失败不应该阻断 App 运行，记录日志并返回空 Map 即可
      logger.e("获取在线状态失败", error: e);
      return {};
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final response = await dio.get(
        '/gateway/search/users',
        queryParameters: {'query': query},
      );
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw handleError(e, 'searchUsers');
    }
  }

  Future<List<UserSearchResult>> getFriends() async {
    try {
      final response = await dio.get('/gateway/friends');
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw handleError(e, 'getFriends');
    }
  }

  Future<int> getPendingFriendRequestsCount() async {
    try {
      final response = await dio.get('/gateway/friends/requests/pending/count');
      return response.data['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response = await dio.get('/gateway/friends/requests/pending');
      return (response.data as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
    await dio
        .post('/gateway/friends/requests', data: {'recipientId': recipientId});
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await dio.post('/gateway/friends/requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await dio.post('/gateway/friends/requests/$requestId/reject');
  }

  // 群组/私聊详情相关
  Future<UserSearchResult> getUserProfile(String userId) async {
    try {
      final users = await getUsersBatch([userId]);
      if (users.isNotEmpty) return users.first;
      throw "User not found: $userId";
    } on DioException catch (e) {
      throw handleError(e, 'getUserProfile');
    }
  }

  Future<List<UserSearchResult>> getUsersBatch(List<String> userIds) async {
    try {
      final response = await dio.post('/gateway/users/batch', data: userIds);
      final List<dynamic> data = response.data;
      return data.map((json) => UserSearchResult.fromJson(json)).toList();
    } on DioException catch (e) {
      throw handleError(e, 'getUsersBatch');
    }
  }
}
