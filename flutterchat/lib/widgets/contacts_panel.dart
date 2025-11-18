// 文件: lib/widgets/contacts_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterchat/bloc/contacts_panel/contacts_panel_bloc.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';

/// 联系人列表面板，现在是一个无状态的、由 BLoC 驱动的组件。
class ContactsPanel extends StatelessWidget {
  final VoidCallback? onAddFriend;
  final VoidCallback? onNavigateToFriendRequests;
  final String? selectedContactId;
  final ValueChanged<Contact> onContactSelected;

  const ContactsPanel({
    super.key,
    required this.onContactSelected,
    this.onAddFriend,
    this.onNavigateToFriendRequests,
    this.selectedContactId,
  });

  @override
  Widget build(BuildContext context) {
    // BlocBuilder 会自动监听 ContactsPanelBloc 的状态变化，并在每次状态更新时重建UI
    return BlocBuilder<ContactsPanelBloc, ContactsPanelState>(
      builder: (context, state) {
        return Container(
          width: 280,
          color: const Color(0xFF474542),
          child: Column(
            children: [
              // 搜索栏和添加按钮
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
                        child: const Icon(Icons.add,
                            size: 20, color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),

              // 好友管理器 (静态 UI)
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
                        Icon(Icons.person_search,
                            size: 18, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('好友管理器',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),

              // 通知条目，数据来自 BLoC state
              _buildNotificationTile('好友通知',
                  count: state.pendingRequestCount,
                  onTap: onNavigateToFriendRequests),
              _buildNotificationTile('群通知', onTap: () {}),

              const Divider(
                  color: Colors.white10, height: 1, indent: 12, endIndent: 12),

              // 好友/群聊切换栏 (静态 UI)
              _buildToggle(),

              // 动态列表部分
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: state.contactGroups.length,
                        itemBuilder: (context, index) {
                          final group = state.contactGroups[index];
                          final isExpanded =
                              state.expandedGroups.contains(group.name);

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
                                    // 发送事件给 BLoC 来处理状态变化
                                    context
                                        .read<ContactsPanelBloc>()
                                        .add(ToggleContactGroup(group.name));
                                  }
                                },
                              ),
                              if (isExpanded)
                                ...group.contacts.map((contact) =>
                                    _buildContactTile(context, contact,
                                        state.selectedContact)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建单个联系人条目
  Widget _buildContactTile(
      BuildContext context, Contact contact, Contact? selectedContact) {
    bool isSelected = selectedContact?.id == contact.id;

    return GestureDetector(
      onTap: () {
        // 发送事件给 BLoC 来更新选中的联系人
        context.read<ContactsPanelBloc>().add(SelectContact(contact));
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

  /// 构建通知条目
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

  /// 构建“好友”/“群聊”切换栏
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
