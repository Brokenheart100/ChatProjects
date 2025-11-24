import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/search_provider.dart'; // 引入搜索 Provider
import 'package:flutterchat/widgets/custom_circle_avatar.dart'; // 复用头像组件
import 'package:flutterchat/widgets/custom_search_field.dart'; // 复用搜索框组件

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with WindowListener {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  // 窗口关闭拦截逻辑保持不变
  @override
  void onWindowClose() async {
    // 对于独立搜索窗口，通常直接关闭即可，不需要确认框
    // 如果你需要确认框，可以保留之前的逻辑
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    // 监听搜索结果
    final resultsAsync = ref.watch(searchResultsProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF2E2D2A),
        child: Scaffold(
          backgroundColor: const Color(0xFF2E2D2A),
          body: Column(
            children: [
              // 1. 自定义标题栏 (包含搜索框)
              _buildTitleBar(),

              // 2. 内容区域 (结果列表)
              Expanded(
                child: resultsAsync.when(
                  data: (results) => _buildResultsList(results),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('搜索出错: $err',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return DragToMoveArea(
      child: Container(
        height: 60, // 稍微高一点以容纳搜索框
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF2E2D2A),
        child: Row(
          children: [
            // 搜索框
            Expanded(
              child: CustomSearchField(
                controller: _searchController,
                hintText: "搜索用户/群组",
                onChanged: (value) {
                  // 更新 Provider 状态，触发搜索
                  ref.read(searchQueryProvider.notifier).set(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            // 窗口控制按钮
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
            ),
            IconButton(
              onPressed: () => windowManager.close(),
              icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<UserSearchResult> results) {
    if (results.isEmpty) {
      // 如果搜索框没内容，显示空提示；如果有内容但没结果，显示无结果
      final query = _searchController.text;
      return Center(
        child: Text(
          query.isEmpty ? '请输入关键词搜索' : '未找到相关用户',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return ListTile(
          leading: CustomCircleAvatar(
            avatarUrl: user.avatarUrl,
            radius: 20,
          ),
          title: Text(
            user.username,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "ID: ${user.userId}",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ElevatedButton(
            onPressed: () {
              // TODO: 实现添加好友或发起聊天
              // 这里可以调用 API 发送好友请求
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4A4A),
              foregroundColor: Colors.white,
            ),
            child: const Text("添加"),
          ),
        );
      },
    );
  }
}
