import 'package:dio/dio.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService() : _apiClient = ApiClient();

  /// 获取好友列表
  Future<List<UserSearchResult>> getFriends() async {
    try {
      final response = await _apiClient.dio.get('/gateway/friends');
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => UserSearchResult.fromJson(json)).toList();
    } on DioException {
      rethrow;
    }
  }

  /// 获取待处理好友请求数量
  Future<int> getPendingFriendRequestsCount() async {
    try {
      final response =
          await _apiClient.dio.get('/gateway/friends/requests/pending/count');
      return response.data['count'] as int;
    } on DioException {
      return 0; // 出错时返回 0
    }
  }

  /// 获取待处理好友请求列表
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    try {
      final response =
          await _apiClient.dio.get('/gateway/friends/requests/pending');
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => FriendRequest.fromJson(json)).toList();
    } on DioException {
      rethrow;
    }
  }

  /// 接受好友请求
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _apiClient.dio.post('/gateway/friends/requests/$requestId/accept');
    } on DioException {
      rethrow;
    }
  }

  /// 拒绝好友请求
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _apiClient.dio.post('/gateway/friends/requests/$requestId/reject');
    } on DioException {
      rethrow;
    }
  }
}
