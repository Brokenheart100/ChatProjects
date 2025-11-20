import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // 1. 私有静态实例，配合 factory 实现单例模式
  static final ApiClient _instance = ApiClient._internal();

  // 2. 工厂构造函数：外界调用 ApiClient() 时，总是返回同一个实例
  factory ApiClient() => _instance;

  late final Dio dio;

  // Token 存储的 Key，必须与登录逻辑里保存的 Key 一致
  static const String _tokenKey = 'auth_token';

  static const String _baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://localhost:7265');

  // 3. 初始化逻辑
  ApiClient._internal() {
    // A. 基础配置
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10), // 连接超时
      receiveTimeout: const Duration(seconds: 30), // 响应超时
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // B. 拦截器配置
    dio.interceptors.add(InterceptorsWrapper(
      // 请求拦截：自动附加 Token
      onRequest: (options, handler) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_tokenKey);

          // 只有当 Token 存在，且请求头里没有手动设置 Authorization 时才添加
          // (防止某些特殊接口需要不带 Token 或带其他 Token)
          if (token != null && token.isNotEmpty) {
            // 检查是否已经在 header 里了
            if (!options.headers.containsKey('Authorization')) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // 打印请求日志 (Debug 用)
          logger.d('🌐 Request: ${options.method} ${options.uri}');
        } catch (e) {
          logger.e("获取 Token 失败", error: e);
        }
        return handler.next(options);
      },

      // 响应拦截：打印结果
      onResponse: (response, handler) {
        logger.d(
            '✅ Response [${response.statusCode}]: ${response.requestOptions.uri}');
        return handler.next(response);
      },

      // 错误拦截：处理 401 和网络异常
      onError: (DioException e, handler) async {
        logger.e('❌ API Error: ${e.response?.statusCode} => ${e.message}');

        if (e.response?.statusCode == 401) {
          logger.w("⚠️ Token 已过期或无效，需要重新登录");
          // TODO: Step 3 时我们会在这里加入“自动跳转到登录页”的逻辑
          // 目前先只清除本地 Token
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
        }

        return handler.next(e);
      },
    ));

    // C. 处理 HTTPS 自签名证书 (开发环境必须)
    // 如果你的 ASP.NET Core 本地开发使用的是自签名证书，Flutter 会报错 HandshakeException
    // 这段代码会忽略证书校验
    if (_baseUrl.contains("https")) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    logger.i("Token 已保存");
  }

  /// 删除本地 Token (用于注销或 Token 过期)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    logger.i("Token 已清除");
  }
}
