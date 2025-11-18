// 文件: lib/services/api_client.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ApiClient 负责所有底层的网络通信配置。
/// 它是一个单例，确保整个应用共享同一个 Dio 实例和配置。
class ApiClient {
  // --- 单例模式 ---
  // 1. 创建一个私有的静态实例
  static final ApiClient _instance = ApiClient._internal();

  // 2. 提供一个公开的工厂构造函数，总是返回同一个实例
  factory ApiClient() {
    return _instance;
  }

  // 3. 私有的内部构造函数，只执行一次
  ApiClient._internal() {
    _initializeDio();
  }
  // -----------------

  late final Dio dio; // 公开 Dio 实例，以便上层服务可以使用

  static const String _tokenKey = 'auth_token';
  static const String _baseUrl = 'https://localhost:7122'; // 您的网关地址

  /// 初始化 Dio 实例和拦截器
  void _initializeDio() {
    // 创建基础 Dio 实例
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // --- 处理 HTTPS 自签名证书 (仅限开发环境) ---
    // (这段代码来自之前的 dio_client.dart)
    if (!bool.fromEnvironment('dart.library.js_util')) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // --- 添加通用拦截器 ---
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 自动附加 Authorization Token
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        logger.i('--> ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.i('<-- ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        logger.e(
            '<-- ${e.response?.statusCode} ${e.requestOptions.uri}\nError: ${e.message}');

        // 遇到 401 错误时，自动清除本地 Token
        if (e.response?.statusCode == 401) {
          await removeToken();
          // 这里可以添加全局导航逻辑，强制跳转到登录页
        }
        return handler.next(e);
      },
    ));
  }

  // --- Token 管理 ---
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
