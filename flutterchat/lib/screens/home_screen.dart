import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart'; // 引入 logger
import 'package:flutterchat/widgets/add_friend_panel.dart';
import 'package:flutterchat/widgets/contact_detail_panel.dart';
import 'package:flutterchat/widgets/contacts_panel.dart';
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
    logger.i("🏠 [HomeScreen] initState");
    if (widget.authResponse != null) {
      logger.i("🔑 [HomeScreen] 使用传入的 AuthResponse 初始化 CurrentUser");
      Future.microtask(() {
        ref.read(currentUserProvider.notifier).setUser(widget.authResponse!);
      });
    }
  }

  Future<void> _logout() async {
    logger.i("🚪 [HomeScreen] 用户点击登出按钮");
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
      logger.w("👋 [HomeScreen] 执行登出逻辑...");
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

    // 监听状态变化打日志
    ref.listen(mainPanelStateProvider, (previous, next) {
      logger.d("🔄 [HomeScreen] 主面板状态切换: $previous -> $next");
    });

    if (currentUser == null) {
      logger.w("⏳ [HomeScreen] CurrentUser 为空，显示加载圈");
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
                    logger.i("👈 [LeftNav] 点击导航栏索引: $index");
                    ref.read(selectedNavIndexProvider.notifier).state = index;

                    if (index == 0) {
                      logger.d("🔄 [LeftNav] 切换到聊天模式");
                      ref.read(mainPanelStateProvider.notifier).state =
                          MainPanelState.chat;
                    } else if (index == 1) {
                      logger.d("🔄 [LeftNav] 切换到联系人模式，并清除选中联系人");
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
    logger.i("🖥️ [LeftPanel] 构建左面板: $mainState");

    switch (mainState) {
      case MainPanelState.chat:
        final conversationListAsync = ref.watch(conversationListProvider);
        final selectedIndex = ref.watch(selectedConversationIndexProvider);

        return conversationListAsync.when(
          data: (conversations) {
            logger.d("📋 [LeftPanel] 会话列表加载完成，共 ${conversations.length} 条");
            return widget_ui.ConversationList(
              conversations: conversations,
              selectedIndex: selectedIndex,
              onTap: (index) {
                logger.i("👆 [ConversationList] 选中会话索引: $index");
                ref.read(selectedConversationIndexProvider.notifier).set(index);
              },
              onAddFriend: () {
                logger.i("➕ [ConversationList] 点击添加好友按钮");
                ref.read(selectedNavIndexProvider.notifier).state = 1;
                ref.read(mainPanelStateProvider.notifier).state =
                    MainPanelState.addFriend;
              },
            );
          },
          loading: () => Container(
              width: 280,
              color: const Color(0xFF3D3D3D),
              child: const Center(child: CircularProgressIndicator())),
          error: (err, stack) {
            logger.e("❌ [LeftPanel] 会话列表加载失败", error: err, stackTrace: stack);
            return Container(
                width: 280,
                color: const Color(0xFF3D3D3D),
                child: Center(child: Text('Error: $err')));
          },
        );

      case MainPanelState.contacts:
        return ContactsPanel(
          onAddFriend: () {
            logger.i("➕ [ContactsPanel] 点击添加好友");
            ref.read(selectedNavIndexProvider.notifier).state = 1;
            ref.read(mainPanelStateProvider.notifier).state =
                MainPanelState.addFriend;
          },
          onNavigateToFriendRequests: () {
            logger.i("🔔 [ContactsPanel] 点击好友请求通知");
            ref.read(mainPanelStateProvider.notifier).state =
                MainPanelState.friendRequests;
            ref.read(selectedContactProvider.notifier).state = null;
          },
        );

      case MainPanelState.addFriend:
      case MainPanelState.friendRequests:
        // 这里实际上应该显示 ContactsPanel，但为了保持之前逻辑一致，我们让它们共用一个左面板逻辑
        // 简单起见，这里还是返回 ContactsPanel，因为 AddFriend 和 Request 通常也是从联系人页进的
        // 但根据你的状态机，这里可能就是想显示一个静态列表
        // 我们这里复用 ContactsPanel 以保持一致性
        return ContactsPanel(
          onAddFriend: () {
            ref.read(mainPanelStateProvider.notifier).state =
                MainPanelState.addFriend;
          },
          onNavigateToFriendRequests: () {
            ref.read(mainPanelStateProvider.notifier).state =
                MainPanelState.friendRequests;
          },
        );
    }
  }

  Widget _buildRightPanel() {
    final mainState = ref.watch(mainPanelStateProvider);
    // logger.v("🖥️ [RightPanel] 构建右面板: $mainState");

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
            logger.d(
                "💬 [RightPanel] 显示聊天面板: ${conversation.name} (ID: ${conversation.id})");
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
        logger.d("➕ [RightPanel] 显示添加好友面板");
        return const Expanded(child: AddFriendPanel());

      case MainPanelState.friendRequests:
        logger.d("🔔 [RightPanel] 显示好友请求面板");
        return const Expanded(child: FriendRequestsPanel());

      case MainPanelState.contacts:
        final selectedContact = ref.watch(selectedContactProvider);
        if (selectedContact == null) {
          return _buildPlaceholder("请选择联系人");
        }
        logger.d("👤 [RightPanel] 显示联系人详情: ${selectedContact.name}");
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
