// 文件: lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/services/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  // 依赖于 ApiClient 单例
  AuthService() : _apiClient = ApiClient();

  /// 用户登录
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/gateway/auth/login',
        data: {'username': username, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);
      // 登录成功后，通过 ApiClient 保存 Token
      await _apiClient.saveToken(authResponse.token);
      return authResponse;
    } on DioException {
      rethrow; // 重新抛出，让 UI 层捕获
    }
  }

  /// 用户注册
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      await _apiClient.dio.post(
        '/gateway/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'avatarUrl': avatarUrl,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  /// 恢复会话 (自动登录)
  Future<AuthResponse> getSession() async {
    try {
      final response = await _apiClient.dio.get('/gateway/auth/session');
      final authResponse = AuthResponse.fromJson(response.data);
      // 刷新 Token
      await _apiClient.saveToken(authResponse.token);
      return authResponse;
    } on DioException {
      // 如果 getSession 失败 (例如 401)，ApiClient 的拦截器已经清除了 Token
      rethrow;
    }
  }

  /// 用户注销
  Future<void> logout() async {
    // 注销的核心就是清除本地 Token
    await _apiClient.removeToken();
  }
}
