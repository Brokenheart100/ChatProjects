import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/providers/contact_provider.dart';
import 'package:flutterchat/screens/home_screen.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';

enum ContactMenuAction { addFriend, createGroup }

// 1. 改回 ConsumerStatefulWidget 以管理 Tab 状态
class ContactsPanel extends ConsumerStatefulWidget {
  final VoidCallback? onAddFriend;
  final VoidCallback? onNavigateToFriendRequests;
  final VoidCallback? onCreateGroup;

  const ContactsPanel({
    super.key,
    this.onAddFriend,
    this.onNavigateToFriendRequests,
    this.onCreateGroup,
  });

  @override
  ConsumerState<ContactsPanel> createState() => _ContactsPanelState();
}

class _ContactsPanelState extends ConsumerState<ContactsPanel> {
  // 2. 本地状态：0 = 好友, 1 = 群聊
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
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
                _buildPopupMenuButton(context),
              ],
            ),
          ),

          // 好友管理器
          _buildManagerButton(),

          _buildNotificationTile(
            '好友通知',
            count: requestCountAsync.value ?? 0,
            onTap: widget.onNavigateToFriendRequests,
          ),
          _buildNotificationTile('群通知', onTap: () {}),

          const Divider(
              color: Colors.white10, height: 1, indent: 12, endIndent: 12),

          // 3. Tab 切换栏
          _buildToggle(),

          // 动态列表区域
          Expanded(
            child: contactListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text('加载失败', style: TextStyle(color: Colors.white54))),
              data: (allGroups) {
                // 4. 核心逻辑：根据 Tab 筛选分组
                final filteredGroups = _filterGroups(allGroups);

                if (filteredGroups.isEmpty) {
                  return const Center(
                      child: Text("暂无数据",
                          style: TextStyle(color: Colors.white24)));
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 筛选逻辑
  List<ContactGroup> _filterGroups(List<ContactGroup> allGroups) {
    if (_currentTab == 0) {
      // 好友 Tab：显示 "新的朋友", "我的好友", 排除 "我的群聊"
      return allGroups.where((g) => g.name != '我的群聊').toList();
    } else {
      // 群聊 Tab：只显示 "我的群聊"
      return allGroups.where((g) => g.name == '我的群聊').toList();
    }
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
            _buildTabItem("好友", 0),
            _buildTabItem("群聊", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5A5855) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 13)),
          ),
        ),
      ),
    );
  }

  // ... 下面的方法 (Tile, Button 等) 保持不变，直接复制即可 ...

  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<ContactMenuAction>(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      offset: const Offset(0, 40),
      onSelected: (ContactMenuAction value) {
        if (value == ContactMenuAction.addFriend) {
          widget.onAddFriend?.call();
        } else if (value == ContactMenuAction.createGroup) {
          widget.onCreateGroup?.call();
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<ContactMenuAction>>[
        const PopupMenuItem<ContactMenuAction>(
          value: ContactMenuAction.addFriend,
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined,
                  color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('加好友/群',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<ContactMenuAction>(
          value: ContactMenuAction.createGroup,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('发起群聊', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF5A5855),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, size: 20, color: Colors.white54),
      ),
    );
  }

  Widget _buildContactTile(
      WidgetRef ref, Contact contact, Contact? selectedContact) {
    // logger.i("👤 [ContactsPanel] 渲染: ${contact.name}");
    final isSelected = selectedContact?.id == contact.id;

    return GestureDetector(
      onTap: () {
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

  Widget _buildManagerButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
    );
  }
}
