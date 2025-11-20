import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterchat/bloc/contacts_panel/contacts_panel_bloc.dart';
import 'package:flutterchat/bloc/conversation/conversation_bloc.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:flutterchat/widgets/add_friend_panel.dart';
import 'package:flutterchat/widgets/contact_detail_panel.dart';
import 'package:flutterchat/widgets/friend_requests_panel.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../widgets/chat_panel.dart';
import '../widgets/contacts_panel.dart';
import '../widgets/conversation_list.dart';
import '../widgets/left_nav_rail.dart';
import '../widgets/title_bar.dart';
import 'package:uuid/uuid.dart'; // 引入库

enum MainPanelState {
  chat,
  contacts,
  addFriend,
  friendRequests,
}

class HomeScreen extends StatefulWidget {
  final AuthResponse? authResponse;
  const HomeScreen({super.key, this.authResponse});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // UI 状态
  int _selectedNavIndex = 0;
  MainPanelState _currentMainState = MainPanelState.chat;

  // 数据状态
  AuthResponse? _currentUser;
  String _fullAvatarUrl = '';
  Contact? _selectedContact;

  // 依赖和 BLoC 实例
  final _apiService = ApiService();
  late final ContactsPanelBloc _contactsPanelBloc;

  MqttService? _mqttService;
  @override
  void initState() {
    super.initState();
    // 创建 BLoC 实例并通过它加载数据
    _contactsPanelBloc = ContactsPanelBloc(apiService: _apiService)
      ..add(LoadContactsData());

    if (widget.authResponse != null) {
      _currentUser = widget.authResponse;
      _fullAvatarUrl = _apiService.getFullAvatarUrl(_currentUser?.avatarUrl);
      // 此时 currentUser 已有，可以安全地初始化 MQTT
      _initializeAndConnectMqtt();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里初始化依赖于 context 的服务，并且只初始化一次
    if (_currentUser == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AuthResponse) {
        setState(() {
          _currentUser = args;
          _fullAvatarUrl =
              _apiService.getFullAvatarUrl(_currentUser?.avatarUrl);
          // --- 核心新增：在获取到用户信息后，初始化并连接 MQTT ---
          _initializeAndConnectMqtt();
        });
      }
    } else if (_mqttService == null) {
      // 针对自动登录场景，currentUser 在 initState 就有了，但 mqtt 还没初始化
      _initializeAndConnectMqtt();
    }
  }

  void _initializeAndConnectMqtt() {
    if (_currentUser == null) return;
    const mqttServer =
        String.fromEnvironment('MQTT_HOST', defaultValue: 'localhost');
    _mqttService =
        MqttService(serverAddress: mqttServer, userId: _currentUser!.userId);
    _mqttService!.connect();
  }

  @override
  void dispose() {
    _contactsPanelBloc.close(); // 释放 BLoC 资源
    _mqttService?.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(/* ... */),
    );
    if (confirm == true) {
      await _apiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 MultiBlocProvider 注入所有需要的 Bloc
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _contactsPanelBloc),
        // 注入 ConversationBloc
        BlocProvider(
          create: (context) => ConversationBloc(
            apiService: _apiService,
            mqttService: _mqttService,
            currentUserId: _currentUser?.userId ?? '',
          )..add(ConversationStarted()),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF363636),
        body: Column(
          children: [
            CustomTitleBar(avatarUrl: _fullAvatarUrl),
            Expanded(
              child: Row(
                children: [
                  // 左侧导航栏
                  LeftNavRail(
                    selectedIndex: _selectedNavIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedNavIndex = index;
                        if (index == 0)
                          _currentMainState = MainPanelState.chat;
                        else if (index == 1)
                          _currentMainState = MainPanelState.contacts;
                      });
                    },
                    avatarUrl: _fullAvatarUrl,
                    onLogout: () {}, // 填入你的登出逻辑
                  ),

                  // 主面板内容
                  _buildBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 使用 Builder 获取包含 Bloc 的 context
    return Expanded(
      child: Builder(builder: (context) {
        // 可以在这里处理 _startConversation 的回调逻辑
        return Row(
          children: [
            // 左侧列表 (会话列表 OR 联系人列表)
            _buildLeftPanel(context),

            // 右侧详情 (聊天框 OR 详情页)
            _buildRightPanel(context),
          ],
        );
      }),
    );
  }

  void _startConversation(Contact contact) {
    setState(() {
      _selectedNavIndex = 0;
      _currentMainState = MainPanelState.chat;
    });
  }

// 构建左侧面板
  Widget _buildLeftPanel(BuildContext context) {
    switch (_currentMainState) {
      case MainPanelState.chat:
        // 聊天状态下，左侧是会话列表
        return BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
            return ConversationList(
              conversations: state.conversations,
              selectedIndex: state.selectedIndex,
              onTap: (index) {
                context
                    .read<ConversationBloc>()
                    .add(ConversationSelected(index));
              },
              onAddFriend: () {
                setState(() {
                  _selectedNavIndex = 1;
                  _currentMainState = MainPanelState.addFriend;
                });
              },
            );
          },
        );

      case MainPanelState.contacts:
      case MainPanelState.friendRequests:
      case MainPanelState.addFriend: // <-- 关键！addFriend 状态现在也使用 ContactsPanel
      default:
        // 在所有与“联系人”相关的视图下，左侧都固定为 ContactsPanel
        return ContactsPanel(
          selectedContactId: _selectedContact?.id,
          onContactSelected: (contact) {
            setState(() {
              _selectedContact = contact;
              _currentMainState = MainPanelState.contacts;
            });
          },
          onAddFriend: () {
            setState(() {
              _currentMainState = MainPanelState.addFriend;
              _selectedContact = null;
            });
          },
          onNavigateToFriendRequests: () {
            setState(() {
              _currentMainState = MainPanelState.friendRequests;
              _selectedContact = null;
            });
          },
        );
    }
  }

  /// 构建右侧面板
  Widget _buildRightPanel(BuildContext context) {
    switch (_currentMainState) {
      case MainPanelState.chat:
        return BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
            final selectedConv = state.selectedConversation;
            if (selectedConv == null) {
              return const Expanded(
                  child: Center(
                      child: Text("暂无会话",
                          style: TextStyle(color: Colors.white54))));
            }
            // 返回 Step 1 重构后的 ChatPanel
            // 这里的 Key 很重要，保证切换会话时 ChatPanel 会重绘
            return Expanded(
              child: ChatPanel(
                key: ValueKey(selectedConv.id),
                conversation: selectedConv,
                currentUserId: _currentUser!.userId,
                mqttService: _mqttService,
              ),
            );
          },
        );
      case MainPanelState.contacts:
        // 这里需要稍微修改一下，把 startConversation 传进去
        // 这里可以用 BlocListener 或者直接透传回调
        // 简单起见，我们假设 ContactDetailPanel 接收回调：
        return BlocBuilder<ContactsPanelBloc, ContactsPanelState>(
            builder: (context, state) {
          if (state.selectedContact == null) return Container();
          return ContactDetailPanel(
            contact: state.selectedContact!,
            onSendMessage: (contact) {
              // 触发 ConversationBloc 的创建事件
              context
                  .read<ConversationBloc>()
                  .add(ConversationCreated(contact));
              // 切换 UI
              setState(() {
                _selectedNavIndex = 0;
                _currentMainState = MainPanelState.chat;
              });
            },
          );
        });
      case MainPanelState.friendRequests:
        return const Expanded(child: FriendRequestsPanel());

      // --- 核心修改：添加这个 case ---
      case MainPanelState.addFriend:
        return const Expanded(child: AddFriendPanel());
    }
  }

  /// 构建联系人页面的右侧面板
  Widget _buildContactsRightPanel(ContactsPanelState state) {
    // 优先判断 HomeScreen 的主状态
    if (_currentMainState == MainPanelState.friendRequests) {
      return const Expanded(child: FriendRequestsPanel());
    }

    if (_currentMainState == MainPanelState.addFriend) {
      return const Expanded(child: AddFriendPanel());
    }

    // 如果主状态是 contacts，则根据 BLoC 的状态来决定
    if (state.selectedContact == null) {
      return _buildPlaceholder("请从左侧选择一个联系人查看详情");
    } else {
      return ContactDetailPanel(
        contact: state.selectedContact!,
        onSendMessage: _startConversation,
      );
    }
  }

  /// 构建通用的占位符 Widget
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
