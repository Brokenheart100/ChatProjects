import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/screens/create_group_screen.dart';
import 'package:flutterchat/widgets/chat_panel.dart';
// 给 ConversationList 起别名以避免命名冲突（如果 Provider 同名）
import 'package:flutterchat/widgets/conversation_list.dart' as ui;

// 定义当前视图的子状态
enum GroupChatSubState {
  normal, // 显示聊天窗口
  createGroup, // 显示创建群聊表单
}

// 局部状态 Provider (autoDispose 保证离开页面后重置)
final groupChatSubStateProvider = StateProvider.autoDispose<GroupChatSubState>(
    (ref) => GroupChatSubState.normal);

class GroupChatView extends ConsumerWidget {
  const GroupChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 1. 左侧列表区域
        _buildLeftPanel(context, ref),

        // 2. 右侧详情/内容区域
        Expanded(
          child: _buildRightPanel(context, ref),
        ),
      ],
    );
  }

  /// 构建左侧面板
  Widget _buildLeftPanel(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(conversationListProvider);
    final selectedIndex = ref.watch(selectedConversationIndexProvider);

    return listAsync.when(
      data: (conversations) {
        // (可选) 如果只想显示群聊，可以在这里过滤
        // final groupConversations = conversations.where((c) => c.isGroup).toList();

        return ui.ConversationList(
          conversations: conversations, // 或者传 groupConversations
          selectedIndex: selectedIndex,
          onTap: (index) {
            // 选中会话
            ref.read(selectedConversationIndexProvider.notifier).set(index);
            // 确保右侧切回聊天模式
            ref.read(groupChatSubStateProvider.notifier).state =
                GroupChatSubState.normal;
          },
          onAddFriend: () {
            // 这里通常不处理加好友，或者跳转到联系人 Tab
            // context.go('/contacts');
          },
          onCreateGroup: () {
            // 切换右侧视图为“创建群聊”
            ref.read(groupChatSubStateProvider.notifier).state =
                GroupChatSubState.createGroup;
          },
        );
      },
      loading: () => Container(
        width: 280,
        color: const Color(0xFF3D3D3D),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        width: 280,
        color: const Color(0xFF3D3D3D),
        child: Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  /// 构建右侧面板
  Widget _buildRightPanel(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(groupChatSubStateProvider);

    // 1. 如果处于创建群聊状态
    if (subState == GroupChatSubState.createGroup) {
      return const CreateGroupScreen();
    }

    // 2. 正常聊天状态
    final listAsync = ref.watch(conversationListProvider);
    final selectedIndex = ref.watch(selectedConversationIndexProvider);

    return listAsync.when(
      data: (conversations) {
        if (conversations.isEmpty || selectedIndex >= conversations.length) {
          return Container(
            color: const Color(0xFF333333),
            child: const Center(
              child: Text("暂无会话", style: TextStyle(color: Colors.white54)),
            ),
          );
        }

        final conversation = conversations[selectedIndex];

        // 使用 Key 强制 ChatPanel 在切换会话时重建
        return ChatPanel(
          key: ValueKey(conversation.id),
          conversation: conversation,
        );
      },
      // 加载中占位
      loading: () => Container(color: const Color(0xFF333333)),
      // 错误占位
      error: (_, __) => Container(color: const Color(0xFF333333)),
    );
  }
}
