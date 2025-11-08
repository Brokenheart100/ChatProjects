import 'package:dio/dio.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Brokenheart100@qq.com
class ApiService {
  final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _baseUrl = 'https://localhost:7265';

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    logger.i('Attempting to register user: $username'); // Info 级别日志
    try {
      final response = await _dio.post(
        '/gateway/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );
      logger.i(
          'Registration successful for user: $username, Status: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleError(e); // 错误处理交给 _handleError
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    logger.i('Attempting to log in user: $username'); // Info 级别日志
    try {
      final response = await _dio.post(
        '/gateway/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        logger.i('Login successful for user: $username');
        final token = response.data['token'];
        logger.d(
            'Received token: ${token.substring(0, 15)}...'); // Debug 级别日志，只显示部分 token
        await saveToken(token);
      } else {
        throw 'Login failed, token not received.';
      }
    } on DioException catch (e) {
      throw _handleError(e); // 错误处理交给 _handleError
    }
  }

  // 统一的错误处理，现在使用 logger
  String _handleError(DioException e) {
    // 使用 Error 级别日志记录完整的错误对象和堆栈跟踪
    logger.e(
      'ApiService Error',
      error: e,
      stackTrace: e.stackTrace,
    );

    if (e.response != null) {
      logger.w('Error Response Data: ${e.response?.data}'); // Warning 级别日志
      if (e.response?.data is String && e.response!.data.isNotEmpty) {
        return e.response!.data;
      }
      return '服务器错误, 状态码: ${e.response?.statusCode}';
    } else {
      logger.w('Network or other error: ${e.message}');
      return '无法连接到服务器, 请检查网络或服务地址。';
    }
  }

  // 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 保存 Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 获取 Token (用于后续需要授权的请求)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
