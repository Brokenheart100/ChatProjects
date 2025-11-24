import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/friendship_status.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 引入 Provider
import 'package:flutterchat/widgets/custom_circle_avatar.dart'; // 引入组件
import 'package:flutterchat/widgets/custom_search_field.dart';

class AddFriendPanel extends ConsumerStatefulWidget {
  const AddFriendPanel({super.key});

  @override
  ConsumerState<AddFriendPanel> createState() => _AddFriendPanelState();
}

class _AddFriendPanelState extends ConsumerState<AddFriendPanel> {
  final _searchController = TextEditingController();

  bool _isLoading = false;
  List<UserSearchResult> _searchResults = [];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用 Provider
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendRequest(String userId) async {
    try {
      // 使用 Provider
      await ref.read(apiServiceProvider).sendFriendRequest(userId);

      setState(() {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF54514E),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          CustomSearchField(
            controller: _searchController,
            hintText: '输入好友/群组的ID或名称',
            height: 40.0,
            onSubmitted: _performSearch,
            onChanged: (value) {
              if (value.isEmpty) {
                _performSearch('');
              }
            },
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.white.withAlpha(25)),
            const SizedBox(height: 16),
            Text('开始搜索以查找好友和群组',
                style:
                    TextStyle(color: Colors.white.withAlpha(77), fontSize: 16)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.white.withAlpha(77)),
            const SizedBox(height: 16),
            Text('未找到匹配的用户或群组',
                style:
                    TextStyle(color: Colors.white.withAlpha(77), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];

        return ListTile(
          // 使用 CustomCircleAvatar 简化代码
          leading: CustomCircleAvatar(
            avatarUrl: user.avatarUrl,
            radius: 20,
          ),
          title:
              Text(user.username, style: const TextStyle(color: Colors.white)),
          trailing: ElevatedButton(
            onPressed: user.friendshipStatus == FriendshipStatus.notFriend
                ? () => _sendRequest(user.userId)
                : null,
            child: Text(user.friendshipStatus.displayText),
          ),
        );
      },
    );
  }
}
