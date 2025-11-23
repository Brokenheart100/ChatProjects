import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/contact_provider.dart'; // 确保这个文件已创建并生成了 .g.dart
import 'package:flutterchat/screens/home_screen.dart'; // 为了获取 selectedContactProvider
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';

// ✅ 关键点：继承 ConsumerWidget，且构造函数不再需要 onContactSelected
class ContactsPanel extends ConsumerWidget {
  final VoidCallback? onAddFriend;
  final VoidCallback? onNavigateToFriendRequests;

  const ContactsPanel({
    super.key,
    this.onAddFriend,
    this.onNavigateToFriendRequests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听数据
    final contactListAsync = ref.watch(contactListProvider);
    final requestCountAsync = ref.watch(friendRequestCountProvider);
    final expandedGroups = ref.watch(expandedGroupsProvider);
    final selectedContact = ref.watch(selectedContactProvider);

    return Container(
      width: 280,
      color: const Color(0xFF474542),
      child: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Expanded(child: CustomSearchField(hintText: '搜索')),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAddFriend,
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A5855),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        const Icon(Icons.add, size: 20, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),

          // 好友管理器
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5A5855),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('好友管理器',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // 通知栏
          _buildNotificationTile(
            '好友通知',
            count: requestCountAsync.value ?? 0,
            onTap: onNavigateToFriendRequests,
          ),
          _buildNotificationTile('群通知', onTap: () {}),

          const Divider(
              color: Colors.white10, height: 1, indent: 12, endIndent: 12),

          // 切换 Tab
          _buildToggle(),

          // 动态列表区域
          Expanded(
            child: contactListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text('加载失败', style: TextStyle(color: Colors.white54))),
              data: (groups) => ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isExpanded = expandedGroups.contains(group.name);

                  return Column(
                    children: [
                      ListTile(
                        leading: group.contacts.isEmpty
                            ? const SizedBox(width: 24)
                            : Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.chevron_right,
                                color: Colors.white54,
                                size: 20,
                              ),
                        title: Text(group.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        trailing: Text(group.countDisplay,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                        dense: true,
                        onTap: () {
                          if (group.contacts.isNotEmpty) {
                            ref
                                .read(expandedGroupsProvider.notifier)
                                .toggle(group.name);
                          }
                        },
                      ),
                      if (isExpanded)
                        ...group.contacts.map((contact) =>
                            _buildContactTile(ref, contact, selectedContact)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
      WidgetRef ref, Contact contact, Contact? selectedContact) {
    final isSelected = selectedContact?.id == contact.id;

    return GestureDetector(
      onTap: () {
        // ✅ 核心逻辑：直接在组件内部更新全局 Provider，不需要回调
        ref.read(selectedContactProvider.notifier).state = contact;
      },
      child: Container(
        color: isSelected ? const Color(0xFF5A5855) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            CustomCircleAvatar(avatarUrl: contact.avatarUrl, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(contact.remark,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String title,
      {int count = 0, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text(count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
        ],
      ),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF474542),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5A5855),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                    child: Text("好友",
                        style: TextStyle(color: Colors.white, fontSize: 13))),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: const Center(
                    child: Text("群聊",
                        style: TextStyle(color: Colors.white54, fontSize: 13))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
