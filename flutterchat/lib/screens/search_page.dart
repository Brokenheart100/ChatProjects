import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutterchat/providers/message_search_provider.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/highlight_text.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? conversationId; // 可选：如果传入，则只搜该会话；否则搜全局（未来扩展）

  const SearchPage({super.key, this.conversationId});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听搜索结果
    // 注意：这里强制要求 conversationId，如果你做全局搜索，需调整 Provider 逻辑
    final searchAsync = ref.watch(messageSearchProvider(SearchParams(
      query: _query,
      conversationId: widget.conversationId ?? '',
    )));

    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E), // 统一深色背景
      body: Column(
        children: [
          // 1. 自定义标题栏 (包含搜索框)
          _buildSearchHeader(context),

          // 2. 内容区域
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyState() // 没输入时显示空状态或历史
                : searchAsync.when(
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF6584FE)),
                    ),
                    error: (err, stack) => Center(child: Text('搜索出错: $err')),
                    data: (results) {
                      if (results.isEmpty) {
                        return _buildNoResult();
                      }
                      return _buildResultList(results);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- 组件：高端搜索栏 ---
  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF333333),
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F), // 输入框更深一点
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10), // 微弱描边
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true, // 进来自动聚焦
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: const Color(0xFF6584FE),
                  decoration: const InputDecoration(
                    hintText: '搜索聊天记录...',
                    hintStyle: TextStyle(color: Colors.white30),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white30, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9), // 垂直居中
                  ),
                  onChanged: (val) {
                    setState(() {
                      _query = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.pop(),
              child: const Text(
                "取消",
                style: TextStyle(color: Color(0xFF6584FE), fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 组件：结果列表 ---
  Widget _buildResultList(List<MessageSearchResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return InkWell(
          onTap: () {
            // TODO: 点击跳转到聊天页面并定位到该消息
            // context.push('/chat/${widget.conversationId}?jumpTo=${item.messageId}');
          },
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像 (如果有 sender 信息)
                // 这里暂时用一个占位，实际上你可以 fetch UserProfile
                const CustomCircleAvatar(avatarUrl: '', radius: 20),
                const SizedBox(width: 12),

                // 文本区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "用户名称", // 需异步获取
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat('MM-dd HH:mm')
                                .format(item.sentAt.toLocal()),
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ✨✨✨ 核心：高亮文本 ✨✨✨
                      HighlightText(
                        text: item.highlights, // Typesense 返回的带 <mark> 的文本
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                        highlightStyle: const TextStyle(
                            color: Color(0xFF6584FE),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 组件：空状态 (插画风格) ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_search,
              size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(
            "查找与好友的聊天记录",
            style: TextStyle(color: Colors.white.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  // --- 组件：无结果 ---
  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "未找到相关结果",
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}
