import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/services/logger_service.dart'; // ✅ 引入 Logger
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';

enum ConversationMenuAction { createGroup, addFriend, sendFile }

class ConversationList extends ConsumerWidget {
  final List<Conversation> conversations;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCreateGroup;

  const ConversationList({
    super.key,
    required this.conversations,
    required this.selectedIndex,
    required this.onTap,
    this.onAddFriend,
    this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 渲染时日志 (频率较高，如果不调试可注释)
    logger.d("📋 [ConversationList] 渲染列表，共 ${conversations.length} 个会话");

    return Container(
      width: 280,
      color: const Color(0xFF3D3D3D),
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Expanded(child: CustomSearchField(hintText: '搜索')),
                const SizedBox(width: 8),
                _buildPopupMenuButton(context),
              ],
            ),
          ),
          // 列表区域
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final isSelected = selectedIndex == index;
                logger.i(
                    "👆 [ConversationList] : ${conversation.name} (ID: ${conversation.uuid}) recipientId:${conversation.recipientId}");
                return GestureDetector(
                  onTap: () {
                    logger.i(
                        "👆 [ConversationList] 点击会话: ${conversation.name} (ID: ${conversation.uuid})");
                    onTap(index);
                  },
                  onSecondaryTapDown: (details) {
                    logger.i(
                        "🖱️ [ConversationList] 右键点击会话: ${conversation.name}");
                    _showContextMenu(
                        context, ref, details.globalPosition, conversation);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A4A4A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        CustomCircleAvatar(
                          avatarUrl: conversation.avatar,
                          radius: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(conversation.lastMessageAt),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation.lastMessage,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset position,
      Conversation conversation) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      color: const Color(0xFF2E2E2E),
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: <PopupMenuEntry<dynamic>>[
        _buildMenuItem(
          icon: Icons.vertical_align_top,
          text: '置顶',
          onTap: () {
            logger.i("📌 [ConversationList] 点击置顶: ${conversation.name}");
            // TODO: 实现置顶逻辑
          },
        ),
        _buildMenuItem(
          icon: Icons.mark_chat_unread_outlined,
          text: '标记未读',
          onTap: () {
            logger.i("🔴 [ConversationList] 点击标记未读: ${conversation.name}");
          },
        ),
        const PopupMenuDivider(height: 1),
        _buildMenuItem(
          icon: Icons.delete_outline,
          text: '从消息列表中移除',
          onTap: () {
            logger.w(
                "🗑️ [ConversationList] 移除会话: ${conversation.name} (ID: ${conversation.uuid})");
            ref
                .read(conversationListProvider.notifier)
                .delete(conversation.uuid);
          },
        ),
      ],
    );
  }

  PopupMenuItem<dynamic> _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem(
      onTap: onTap,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<ConversationMenuAction>(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      offset: const Offset(0, 40),
      onSelected: (ConversationMenuAction value) {
        logger.i("➕ [ConversationList] 顶部菜单选中: $value");
        if (value == ConversationMenuAction.addFriend) {
          onAddFriend?.call();
        } else if (value == ConversationMenuAction.createGroup) {
          onCreateGroup?.call();
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<ConversationMenuAction>>[
        _buildPopupMenuItem(
            value: ConversationMenuAction.createGroup,
            icon: Icons.add_circle_outline,
            text: '创建群聊'),
        _buildPopupMenuItem(
            value: ConversationMenuAction.addFriend,
            icon: Icons.person_add_alt_1_outlined,
            text: '加好友/群'),
        _buildPopupMenuItem(
            value: ConversationMenuAction.sendFile,
            icon: Icons.offline_bolt_outlined,
            text: '闪传文件'),
      ],
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
            color: const Color(0xFF4A4A4A),
            borderRadius: BorderRadius.circular(4)),
        child: const Icon(Icons.add, size: 20, color: Colors.white54),
      ),
    );
  }

  PopupMenuItem<ConversationMenuAction> _buildPopupMenuItem({
    required ConversationMenuAction value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem<ConversationMenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  // 辅助方法：格式化时间
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
