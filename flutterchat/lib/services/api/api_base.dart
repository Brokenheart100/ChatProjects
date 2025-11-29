import 'package:dio/dio.dart';
import 'package:flutterchat/services/api_client.dart';
import 'package:flutterchat/services/logger_service.dart';

/// API 基础类
/// 所有子模块都基于这个类扩展，共享 Dio 和错误处理逻辑
class ApiBase {
  // 获取单例 Dio
  Dio get dio => ApiClient().dio;

  /// 生成完整头像 URL
  String getFullAvatarUrl(String? objectKey) {
    if (objectKey == null || objectKey.isEmpty) return '';
    if (objectKey.startsWith('http')) return objectKey;
    const minioUrl = 'http://localhost:9000/avatars';
    return '$minioUrl/$objectKey';
  }

  /// 统一错误处理
  String handleError(DioException e, String context) {
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
