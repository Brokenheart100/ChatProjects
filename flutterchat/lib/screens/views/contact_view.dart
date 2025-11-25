import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          onAddFriend: () => ref.read(contactSubStateProvider.notifier).state =
              ContactSubState.addFriend,
          onNavigateToFriendRequests: () => ref
              .read(contactSubStateProvider.notifier)
              .state = ContactSubState.requests,
          onCreateGroup: () {
            // 这里通常是跳转到聊天Tab并打开创建页，为了演示简单，我们暂不实现跨Tab
          },
        ),
        Expanded(child: _buildDetail(ref)),
      ],
    );
  }

  Widget _buildDetail(WidgetRef ref) {
    final subState = ref.watch(contactSubStateProvider);

    switch (subState) {
      case ContactSubState.addFriend:
        return const AddFriendPanel();
      case ContactSubState.requests:
        return const FriendRequestsPanel();
      default:
        final contact = ref.watch(selectedContactProvider);
        if (contact == null) {
          return Container(
              color: const Color(0xFF333333),
              child: const Center(
                  child:
                      Text("请选择联系人", style: TextStyle(color: Colors.white54))));
        }
        return ContactDetailPanel(contact: contact);
    }
  }
}
