import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';

// 简单的搜索结果模型
class MessageSearchResult {
  final String messageId;
  final String content; // 原始内容
  final String highlights; // 带 <mark> 的内容
  final String senderId;
  final DateTime sentAt;

  MessageSearchResult({
    required this.messageId,
    required this.content,
    required this.highlights,
    required this.senderId,
    required this.sentAt,
  });

  factory MessageSearchResult.fromJson(Map<String, dynamic> json) {
    return MessageSearchResult(
      messageId: json['messageId'],
      content: json['content'],
      highlights: json['highlights'], // 后端返回的高亮片段
      senderId: json['senderId'],
      sentAt: DateTime.parse(json['sentAt']),
    );
  }
}

// 搜索参数
class SearchParams {
  final String query;
  final String conversationId; // 如果是在某个会话内搜，传这个；如果是全局搜，可为空
  SearchParams({required this.query, required this.conversationId});
}

// 搜索 Provider
final messageSearchProvider = FutureProvider.family
    .autoDispose<List<MessageSearchResult>, SearchParams>((ref, params) async {
  if (params.query.trim().isEmpty) return [];

  // 防抖 500ms
  await Future.delayed(const Duration(milliseconds: 500));

  final api = ref.read(apiServiceProvider);

  try {
    // 调用 SearchService 的接口
    // 注意：需要在 ApiBase 或 ApiService 中补充 searchMessages 方法
    // 这里直接写 Dio 请求逻辑作为示例
    final response =
        await api.dio.get('/gateway/search/messages', queryParameters: {
      'q': params.query,
      'conversationId': params.conversationId,
    });

    final List list = response.data;
    return list.map((e) => MessageSearchResult.fromJson(e)).toList();
  } on DioException catch (e) {
    logger.e("搜索失败", error: e);
    return [];
  }
});
