import 'package:dio/dio.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api/api_base.dart';

mixin ContactApi on ApiBase {
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

  Future<void> kickGroupMember(
      {required String groupId, required String userId}) async {
    try {
      await dio.post('/gateway/groups/$groupId/kick', data: {'userId': userId});
    } on DioException catch (e) {
      throw handleError(e, 'kickGroupMember');
    }
  }

  Future<List<UserSearchResult>> getGroupMembers(String groupId) async {
    try {
      final response = await dio.get('/gateway/groups/$groupId/members');
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw handleError(e, 'getGroupMembers');
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await dio.post('/gateway/groups/$groupId/leave');
    } on DioException catch (e) {
      throw handleError(e, 'leaveGroup');
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
