import 'package:dio/dio.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/api_client.dart';

mixin AuthApi on ApiBase {
  Future<AuthResponse> login(
      {required String username, required String password}) async {
    try {
      final response = await dio.post(
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
      throw handleError(e, 'login');
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      await dio.post(
        '/gateway/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'avatarUrl': avatarUrl,
        },
      );
    } on DioException catch (e) {
      throw handleError(e, 'register');
    }
  }

  Future<AuthResponse> getSession() async {
    try {
      final response = await dio.get('/gateway/auth/session');
      final authResponse = AuthResponse.fromJson(response.data);
      await ApiClient().saveToken(authResponse.token);
      return authResponse;
    } on DioException catch (e) {
      throw handleError(e, 'getSession');
    }
  }

  Future<void> logout() async {
    await ApiClient().removeToken();
  }

  Future<void> saveToken(String token) async {
    await ApiClient().saveToken(token);
  }
}
