import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/models/friendship_status.dart'; // 1. 引入状态枚举
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/search_provider.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 2. 引入 API Provider
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';

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

  @override
  void onWindowClose() async {
    await windowManager.close();
  }

  // 3. 新增：发送好友请求的逻辑
  Future<void> _sendFriendRequest(String userId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.sendFriendRequest(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("好友请求已发送"), backgroundColor: Colors.green),
        );
        // 刷新搜索结果以更新按钮状态 (变更为"已发送")
        // 这里稍微偷懒一下，直接触发重新搜索
        ref.refresh(searchResultsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("发送失败: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF2E2D2A),
        child: Scaffold(
          backgroundColor: const Color(0xFF2E2D2A),
          body: Column(
            children: [
              _buildTitleBar(),
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
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF2E2D2A),
        child: Row(
          children: [
            Expanded(
              child: CustomSearchField(
                controller: _searchController,
                hintText: "搜索用户/群组",
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).set(value);
                },
              ),
            ),
            const SizedBox(width: 16),
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

        // 4. 核心修改：根据状态显示不同按钮
        final bool isRequestable =
            user.friendshipStatus == FriendshipStatus.notFriend;

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
            // 如果已经是好友或已发送，禁用按钮
            onPressed:
                isRequestable ? () => _sendFriendRequest(user.userId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isRequestable ? const Color(0xFF4A4A4A) : Colors.transparent,
              foregroundColor: isRequestable ? Colors.white : Colors.grey,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.grey,
              side: isRequestable
                  ? null
                  : const BorderSide(color: Colors.grey, width: 1),
            ),
            child: Text(
                user.friendshipStatus.displayText), // 显示 "添加", "已发送", "已是好友"
          ),
        );
      },
    );
  }
}
