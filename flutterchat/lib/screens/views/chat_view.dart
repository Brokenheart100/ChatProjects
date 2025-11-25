import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/widgets/chat_panel.dart';
import 'package:flutterchat/widgets/conversation_list.dart' as ui;
import 'package:flutterchat/screens/create_group_screen.dart';

// 定义聊天模块内部的子状态
enum ChatSubState { normal, createGroup }

final chatSubStateProvider =
    StateProvider<ChatSubState>((ref) => ChatSubState.normal);

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 左：会话列表
        _buildList(ref),
        // 右：聊天详情 或 创建群聊
        Expanded(child: _buildDetail(ref)),
      ],
    );
  }

  Widget _buildList(WidgetRef ref) {
    final listAsync = ref.watch(conversationListProvider);
    final selectedIndex = ref.watch(selectedConversationIndexProvider);

    return listAsync.when(
      // 2. 核心修复：使用 ui.ConversationList 调用组件
      data: (list) => ui.ConversationList(
        conversations: list,
        selectedIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedConversationIndexProvider.notifier).set(index);
          ref.read(chatSubStateProvider.notifier).state = ChatSubState.normal;
        },
        onAddFriend: () {
          // 这里的逻辑如果需要跨 Tab 跳转联系人，GoRouter 会很方便
          // 暂时留空或者打印日志
          debugPrint("点击添加好友");
        },
        onCreateGroup: () {
          ref.read(chatSubStateProvider.notifier).state =
              ChatSubState.createGroup;
        },
      ),
      loading: () => Container(
          width: 280,
          color: const Color(0xFF3D3D3D),
          child: const Center(child: CircularProgressIndicator())),
      error: (e, s) => Container(
          width: 280,
          color: const Color(0xFF3D3D3D),
          child: Center(child: Text("Error: $e"))),
    );
  }

  Widget _buildDetail(WidgetRef ref) {
    final subState = ref.watch(chatSubStateProvider);

    if (subState == ChatSubState.createGroup) {
      return const CreateGroupScreen();
    }

    final list = ref.watch(conversationListProvider).valueOrNull ?? [];
    final idx = ref.watch(selectedConversationIndexProvider);

    if (list.isEmpty || idx >= list.length) {
      return Container(
          color: const Color(0xFF333333),
          child: const Center(
              child: Text("暂无会话", style: TextStyle(color: Colors.white54))));
    }

    final conversation = list[idx];
    return ChatPanel(
        key: ValueKey(conversation.id), conversation: conversation);
  }
}
