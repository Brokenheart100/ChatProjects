import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart';

part 'search_provider.g.dart';

// 1. 搜索关键词状态
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String query) => state = query;
}

// 2. 搜索结果 Provider (自动监听关键词变化)
@riverpod
Future<List<UserSearchResult>> searchResults(SearchResultsRef ref) async {
  // 监听关键词
  final query = ref.watch(searchQueryProvider);

  // 如果为空，返回空列表
  if (query.trim().isEmpty) return [];

  // 稍微延迟一下，防抖 (Debounce) 效果，避免每输入一个字母都请求
  // 注意：在生产环境中建议使用专业的防抖库，这里用简单延迟演示
  await Future.delayed(const Duration(milliseconds: 300));

  final api = ref.read(apiServiceProvider);
  // 调用 API 搜索
  return await api.searchUsers(query);
}
