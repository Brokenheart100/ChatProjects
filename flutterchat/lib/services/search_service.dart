import 'package:dio/dio.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_client.dart';

class SearchService {
  final ApiClient _apiClient;
  SearchService() : _apiClient = ApiClient();

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/gateway/search/users',
        queryParameters: {'query': query},
      );
      final List<dynamic> jsonList = response.data;
      return jsonList.map((json) => UserSearchResult.fromJson(json)).toList();
    } on DioException {
      rethrow;
    }
  }
}
