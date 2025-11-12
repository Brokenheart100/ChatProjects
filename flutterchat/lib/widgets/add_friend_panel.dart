// 文件: lib/widgets/add_friend_panel.dart

import 'package:flutter/material.dart';
import 'package:flutterchat/models/friendship_status.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_service.dart'; // 引入 ApiService
import 'package:flutterchat/widgets/custom_search_field.dart'; // 引入可复用组件

// 1. StatefulWidget 类本身保持干净，只负责创建 State
class AddFriendPanel extends StatefulWidget {
  const AddFriendPanel({super.key});

  @override
  State<AddFriendPanel> createState() => _AddFriendPanelState();
}

// 2. 所有的状态、控制器和方法都应该在 State 类中
class _AddFriendPanelState extends State<AddFriendPanel> {
  // --- 把所有状态变量和控制器“搬”到这里 ---
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  List<UserSearchResult> _searchResults = [];
  // ------------------------------------

  // --- 把所有方法也“搬”到这里 ---

  // 搜索用户的核心方法
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // 使用 setState 来清空列表并刷新UI
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // 使用 setState 来显示加载动画并刷新UI
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _apiService.searchUsers(query);
      // 使用 setState 来更新搜索结果并刷新UI
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // 可以在这里显示一个 SnackBar 错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: ${e.toString()}')),
        );
      }
    } finally {
      // 确保在 finally 块中也使用 setState 来隐藏加载动画
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 发送好友请求
  Future<void> _sendRequest(String userId) async {
    // 这里可以加一个加载状态，防止用户重复点击
    try {
      await _apiService.sendFriendRequest(userId);
      // 请求成功后，更新UI，比如禁用按钮或显示"已发送"
      setState(() {
        // 找到对应的用户，并更新其状态
        final index =
            _searchResults.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _searchResults[index].friendshipStatus = FriendshipStatus.pending;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('好友请求已发送！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('发送失败: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 记得在 State 销毁时，释放控制器资源 ---
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 3. build 方法也属于 State 类，负责构建 UI
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF54514E),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          const Text(
            '添加好友或群组',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 搜索框
          CustomSearchField(
            controller: _searchController, // 关联控制器
            hintText: '输入好友/群组的ID或名称',
            height: 40.0,
            onSubmitted: _performSearch, // 按回车时触发搜索
            onChanged: (value) {
              if (value.isEmpty) {
                _performSearch('');
              }
            },
          ),
          const SizedBox(height: 30),

          // 结果区域
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // 加载时显示菊花
                : _buildResultsList(), // 加载完成显示结果
          ),
        ],
      ),
    );
  }

  // 4. 构建搜索结果列表的辅助方法
  Widget _buildResultsList() {
    // 如果没有输入，显示初始提示
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.white.withAlpha(25)),
            const SizedBox(height: 16),
            Text('开始搜索以查找好友和群组',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 16)),
          ],
        ),
      );
    }

    // 如果有输入但没有结果
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('未找到匹配的用户或群组',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 16)),
          ],
        ),
      );
    }

    // 显示搜索结果
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        // 假设 UserSearchResult 模型中有一个 'friendshipStatus' 字段
        final bool isPending =
            user.friendshipStatus == FriendshipStatus.pending;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(_apiService.getFullAvatarUrl(user.avatarUrl))
                    : null, // 如果没有头像，可以显示一个占位符
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title:
              Text(user.username, style: const TextStyle(color: Colors.white)),
          trailing: ElevatedButton(
            // 如果请求已发送，则禁用按钮并改变文字
            onPressed: user.friendshipStatus == FriendshipStatus.notFriend
                ? () => _sendRequest(user.userId)
                : null,
            // --- 核心修改：使用我们定义的 displayText 扩展 ---
            child: Text(user.friendshipStatus.displayText),
          ),
        );
      },
    );
  }
}
