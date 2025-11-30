import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/widgets/chat_panel.dart';
import 'package:flutterchat/widgets/conversation_list.dart' as ui;

// 局部状态：管理群聊视图下，右侧显示什么（默认显示空，或者选中的会话）
// 这里我们复用全局的 selectedConversationIndexProvider，或者你可以新建一个局部 Provider

class GroupListView extends ConsumerWidget {
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 左侧：只显示群聊列表
        _buildGroupList(context, ref),

        // 右侧：聊天详情
        Expanded(child: _buildDetail(context, ref)),
      ],
    );
  }

  Widget _buildGroupList(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(conversationListProvider);
    final selectedIndex = ref.watch(selectedConversationIndexProvider);

    return listAsync.when(
      data: (conversations) {
        // ✅ 核心逻辑：过滤只显示群聊
        final groupConversations =
            conversations.where((c) => c.isGroup).toList();

        return ui.ConversationList(
          conversations: groupConversations, // 传入过滤后的列表
          selectedIndex: selectedIndex,
          onTap: (index) {
            // 注意：这里的 index 是过滤后列表的 index
            // 我们需要找到这个群在原始列表中的 index，以便正确选中
            final selectedGroup = groupConversations[index];
            final realIndex =
                conversations.indexWhere((c) => c.uuid == selectedGroup.uuid);

            ref.read(selectedConversationIndexProvider.notifier).set(realIndex);
          },
          // 群聊列表页不需要显示“加好友”，可以留空或者用来创建新群
          onAddFriend: null,
          onCreateGroup: () {
            // 跳转到创建群聊页 (如果需要的话)
            // context.push('/create_group');
          },
        );
      },
      loading: () => Container(
          width: 280,
          color: const Color(0xFF3D3D3D),
          child: const Center(child: CircularProgressIndicator())),
      error: (err, stack) => Container(
          width: 280,
          color: const Color(0xFF3D3D3D),
          child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationListProvider).valueOrNull ?? [];
    final idx = ref.watch(selectedConversationIndexProvider);

    // 如果选中的索引有效，且对应的会话是群聊，则显示
    if (idx >= 0 && idx < list.length) {
      final conversation = list[idx];
      if (conversation.isGroup) {
        return ChatPanel(
          key: ValueKey(conversation.id),
          conversation: conversation,
        );
      }
    }

    return Container(
      color: const Color(0xFF333333),
      child: const Center(
        child: Text("请选择一个群聊", style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
