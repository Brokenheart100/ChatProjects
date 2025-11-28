import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/screens/create_group_screen.dart';
import 'package:flutterchat/screens/home_screen.dart'; // 引用 selectedContactProvider
import 'package:flutterchat/widgets/add_friend_panel.dart';
import 'package:flutterchat/widgets/contact_detail_panel.dart';
import 'package:flutterchat/widgets/contacts_panel.dart';
import 'package:flutterchat/widgets/friend_requests_panel.dart';

// 联系人模块内部状态
enum ContactSubState { normal, addFriend, requests, createGroup }

final contactSubStateProvider =
    StateProvider<ContactSubState>((ref) => ContactSubState.normal);

class ContactView extends ConsumerWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        ContactsPanel(
          onAddFriend: () {
            // 1. 切换子状态
            ref.read(contactSubStateProvider.notifier).state =
                ContactSubState.addFriend;
            // 2. 🚨 必须清空选中的联系人，否则右侧可能还是显示详情
            ref.read(selectedContactProvider.notifier).state = null;
          },
          onNavigateToFriendRequests: () {
            ref.read(contactSubStateProvider.notifier).state =
                ContactSubState.requests;
            // 🚨 清空选中
            ref.read(selectedContactProvider.notifier).state = null;
          },
          onCreateGroup: () {
            // ✅ 补全逻辑：跳转到创建群聊面板
            ref.read(contactSubStateProvider.notifier).state =
                ContactSubState.createGroup;
            // 🚨 清空选中
            ref.read(selectedContactProvider.notifier).state = null;
          },
        ),
        Expanded(child: _buildDetail(ref)),
      ],
    );
  }

  Widget _buildDetail(WidgetRef ref) {
    final subState = ref.watch(contactSubStateProvider);
    final selectedContact = ref.watch(selectedContactProvider);

    if (selectedContact != null) {
      return ContactDetailPanel(contact: selectedContact);
    }

    switch (subState) {
      case ContactSubState.addFriend:
        return const AddFriendPanel();
      case ContactSubState.requests:
        return const FriendRequestsPanel();
      case ContactSubState.createGroup:
        return const CreateGroupScreen(); // ✅ 显示创建群聊
      case ContactSubState.normal:
        return Container(
          color: const Color(0xFF333333),
          child: const Center(
            child: Text("请选择联系人", style: TextStyle(color: Colors.white54)),
          ),
        );
    }
  }
}
