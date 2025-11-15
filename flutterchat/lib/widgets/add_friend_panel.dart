// 文件: lib/widgets/add_friend_panel.dart
// 功能：添加好友/群组的面板组件，支持搜索用户、显示搜索结果及发送好友请求

// 导入Flutter基础组件库
import 'package:flutter/material.dart';
// 导入好友关系状态枚举（用于标记用户间的好友关系：非好友/待确认等）
import 'package:flutterchat/models/friendship_status.dart';
// 导入用户搜索结果模型（存储搜索到的用户信息：ID、用户名、头像等）
import 'package:flutterchat/models/user_search_result.dart';
// 导入API服务类（处理网络请求：搜索用户、发送好友请求等）
import 'package:flutterchat/services/api_service.dart';
// 导入自定义搜索框组件（复用的搜索输入控件）
import 'package:flutterchat/widgets/custom_search_field.dart';

// 1. 有状态组件：添加好友面板主组件
// 负责创建状态类，本身不存储状态或业务逻辑
class AddFriendPanel extends StatefulWidget {
  const AddFriendPanel({super.key});

  @override
  State<AddFriendPanel> createState() => _AddFriendPanelState();
}

// 2. 状态管理类：处理面板的所有状态、业务逻辑和UI构建
class _AddFriendPanelState extends State<AddFriendPanel> {
  // --- 状态变量与控制器 ---
  // API服务实例：用于调用搜索用户、发送好友请求等接口
  final _apiService = ApiService();
  // 搜索输入控制器：管理搜索框的文本输入（获取输入内容、清空等）
  final _searchController = TextEditingController();

  // 加载状态标记：控制是否显示加载动画（true表示正在加载）
  bool _isLoading = false;
  // 搜索结果列表：存储从API获取的用户搜索结果
  List<UserSearchResult> _searchResults = [];
  // -----------------------

  // --- 核心业务方法 ---

  /// 执行用户搜索的方法
  /// [query]：搜索关键词（用户ID或名称）
  Future<void> _performSearch(String query) async {
    // 若搜索关键词为空，清空结果列表并刷新UI
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // 显示加载动画（更新状态为加载中）
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用API服务搜索用户，获取结果
      final results = await _apiService.searchUsers(query);
      // 更新搜索结果列表并刷新UI
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // 搜索失败时显示错误提示（检查组件是否仍在树中，避免异常）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: ${e.toString()}')),
        );
      }
    } finally {
      // 无论成功/失败，最终隐藏加载动画（确保组件未销毁）
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 发送好友请求的方法
  /// [userId]：目标用户的ID
  Future<void> _sendRequest(String userId) async {
    try {
      // 调用API服务发送好友请求
      await _apiService.sendFriendRequest(userId);
      // 请求成功后，更新该用户的好友关系状态为"待确认"并刷新UI
      setState(() {
        final index =
            _searchResults.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _searchResults[index].friendshipStatus = FriendshipStatus.pending;
        }
      });
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('好友请求已发送！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // 发送失败时显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('发送失败: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 资源释放 ---
  @override
  void dispose() {
    // 销毁时释放搜索控制器资源（防止内存泄漏）
    _searchController.dispose();
    super.dispose();
  }

  // --- UI构建方法 ---
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF54514E), // 面板背景色（深灰色，统一主题风格）
      padding: const EdgeInsets.all(20.0), // 内边距：整体内容与边缘的间距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 子组件横向占满宽度
        children: [
          // 面板标题
          const Text(
            '添加好友或群组',
            style: TextStyle(
              color: Colors.white, // 文字颜色：白色（与深色背景对比）
              fontSize: 24, // 字体大小
              fontWeight: FontWeight.bold, // 字体粗细
            ),
            textAlign: TextAlign.center, // 文字居中对齐
          ),
          const SizedBox(height: 20), // 标题与搜索框之间的间距

          // 搜索框：复用自定义搜索组件
          CustomSearchField(
            controller: _searchController, // 关联搜索控制器（获取输入内容）
            hintText: '输入好友/群组的ID或名称', // 提示文字
            height: 40.0, // 搜索框高度
            onSubmitted: _performSearch, // 回车提交时触发搜索
            onChanged: (value) {
              // 输入变化时，若为空则清空结果
              if (value.isEmpty) {
                _performSearch('');
              }
            },
          ),
          const SizedBox(height: 30), // 搜索框与结果区域之间的间距

          // 结果区域：占满剩余空间
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator()) // 加载中：显示圆形进度条
                : _buildResultsList(), // 加载完成：显示搜索结果列表
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表的辅助方法
  /// 根据搜索状态（无输入/有输入无结果/有结果）显示不同内容
  Widget _buildResultsList() {
    // 情况1：搜索框为空（未输入任何内容）
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
          children: [
            // 搜索图标（半透明，弱化显示）
            Icon(Icons.search, size: 80, color: Colors.white.withAlpha(25)),
            const SizedBox(height: 16), // 图标与文字间距
            // 提示文字（浅灰色，引导用户输入）
            Text('开始搜索以查找好友和群组',
                style:
                    TextStyle(color: Colors.white.withAlpha(77), fontSize: 16)),
          ],
        ),
      );
    }

    // 情况2：有输入但无匹配结果
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 无结果图标（半透明）
            Icon(Icons.search_off, size: 80, color: Colors.white.withAlpha(77)),
            const SizedBox(height: 16),
            // 无结果提示文字
            Text('未找到匹配的用户或群组',
                style:
                    TextStyle(color: Colors.white.withAlpha(77), fontSize: 16)),
          ],
        ),
      );
    }

    // 情况3：有搜索结果，用列表展示
    return ListView.builder(
      itemCount: _searchResults.length, // 列表项数量=结果数量
      itemBuilder: (context, index) {
        final user = _searchResults[index]; // 当前索引对应的用户
        // 根据好友关系状态决定按钮状态（是否可点击）
        final bool isPending =
            user.friendshipStatus == FriendshipStatus.pending;

        return ListTile(
          leading: CircleAvatar(
            // 头像：优先显示网络图片，无头像则显示默认图标
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(_apiService.getFullAvatarUrl(user.avatarUrl))
                    : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person) // 无头像时的占位图标
                : null,
          ),
          title: Text(user.username, // 显示用户名
              style: const TextStyle(color: Colors.white)), // 文字颜色：白色
          trailing: ElevatedButton(
            // 按钮点击事件：仅当非好友时可发送请求
            onPressed: user.friendshipStatus == FriendshipStatus.notFriend
                ? () => _sendRequest(user.userId)
                : null,
            // 按钮文字：根据好友关系状态动态显示（如"添加好友"/"已发送"）
            child: Text(user.friendshipStatus.displayText),
          ),
        );
      },
    );
  }
}
