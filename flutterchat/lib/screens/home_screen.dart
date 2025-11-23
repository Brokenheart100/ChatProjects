import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/conversation_provider.dart'; // 这里面有 class ConversationList extends _$ConversationList
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/widgets/add_friend_panel.dart';
import 'package:flutterchat/widgets/contact_detail_panel.dart';
import 'package:flutterchat/widgets/friend_requests_panel.dart';
import 'package:flutterchat/widgets/chat_panel.dart';
import 'package:flutterchat/widgets/conversation_list.dart' as widget_ui;
import 'package:flutterchat/widgets/left_nav_rail.dart';
import 'package:flutterchat/widgets/title_bar.dart';

// UI 状态枚举
enum MainPanelState {
  chat,
  contacts,
  addFriend,
  friendRequests,
}

// 简单的 UI 状态 Provider
final mainPanelStateProvider =
    StateProvider<MainPanelState>((ref) => MainPanelState.chat);
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedContactProvider = StateProvider<Contact?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  final AuthResponse? authResponse;
  const HomeScreen({super.key, this.authResponse});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.authResponse != null) {
      Future.microtask(() {
        ref.read(currentUserProvider.notifier).setUser(widget.authResponse!);
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(apiServiceProvider).logout();
      ref.read(currentUserProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final navIndex = ref.watch(selectedNavIndexProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fullAvatarUrl =
        ref.read(apiServiceProvider).getFullAvatarUrl(currentUser.avatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      body: Column(
        children: [
          CustomTitleBar(avatarUrl: fullAvatarUrl),
          Expanded(
            child: Row(
              children: [
                LeftNavRail(
                  selectedIndex: navIndex,
                  onDestinationSelected: (index) {
                    ref.read(selectedNavIndexProvider.notifier).state = index;
                    if (index == 0) {
                      ref.read(mainPanelStateProvider.notifier).state =
                          MainPanelState.chat;
                    } else if (index == 1) {
                      ref.read(mainPanelStateProvider.notifier).state =
                          MainPanelState.contacts;
                      ref.read(selectedContactProvider.notifier).state = null;
                    }
                  },
                  avatarUrl: fullAvatarUrl,
                  onLogout: _logout,
                ),
                _buildBody(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: Row(
        children: [
          _buildLeftPanel(),
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final mainState = ref.watch(mainPanelStateProvider);

    switch (mainState) {
      case MainPanelState.chat:
        // conversationListProvider 是 Riverpod 的 Provider
        final conversationListAsync = ref.watch(conversationListProvider);
        final selectedIndex = ref.watch(selectedConversationIndexProvider);

        return conversationListAsync.when(
          data: (conversations) => widget_ui.ConversationList(
            // 2. 核心修复：使用别名调用 Widget
            conversations: conversations,
            selectedIndex: selectedIndex,
            onTap: (index) {
              ref.read(selectedConversationIndexProvider.notifier).set(index);
            },
            onAddFriend: () {
              ref.read(selectedNavIndexProvider.notifier).state = 1;
              ref.read(mainPanelStateProvider.notifier).state =
                  MainPanelState.addFriend;
            },
          ),
          loading: () => Container(
              width: 280,
              color: const Color(0xFF3D3D3D),
              child: const Center(child: CircularProgressIndicator())),
          error: (err, stack) => Container(
              width: 280,
              color: const Color(0xFF3D3D3D),
              child: Center(child: Text('Error: $err'))),
        );

      case MainPanelState.contacts:
      case MainPanelState.addFriend:
      case MainPanelState.friendRequests:
        // 3. 核心修复：移除了不可达的 default 分支
        return Container(
          width: 280,
          color: const Color(0xFF474542),
          child: const Center(child: Text("联系人列表 (待重构)")),
        );
    }
  }

  Widget _buildRightPanel() {
    final mainState = ref.watch(mainPanelStateProvider);

    switch (mainState) {
      case MainPanelState.chat:
        final conversationListAsync = ref.watch(conversationListProvider);
        final selectedIndex = ref.watch(selectedConversationIndexProvider);

        return conversationListAsync.when(
          data: (conversations) {
            if (conversations.isEmpty ||
                selectedIndex >= conversations.length) {
              return _buildPlaceholder("暂无会话");
            }
            final conversation = conversations[selectedIndex];
            return Expanded(
              child: ChatPanel(
                key: ValueKey(conversation.id),
                conversation: conversation,
              ),
            );
          },
          loading: () =>
              const Expanded(child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Expanded(child: SizedBox()),
        );

      case MainPanelState.addFriend:
        return const Expanded(child: AddFriendPanel());

      case MainPanelState.friendRequests:
        return const Expanded(child: FriendRequestsPanel());

      case MainPanelState.contacts:
        // 4. 核心修复：移除了不可达的 default 分支
        final selectedContact = ref.watch(selectedContactProvider);
        if (selectedContact == null) {
          return _buildPlaceholder("请选择联系人");
        }
        return ContactDetailPanel(
          contact: selectedContact,
        );
    }
  }

  Widget _buildPlaceholder(String message) {
    return Expanded(
      child: Container(
        color: const Color(0xFF54514E),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}
