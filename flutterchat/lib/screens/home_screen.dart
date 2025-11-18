// 文件: lib/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterchat/bloc/contacts_panel/contacts_panel_bloc.dart';
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
  int _selectedConversationIndex = 0;
  MainPanelState _currentMainState = MainPanelState.chat;

  // 数据状态
  AuthResponse? _currentUser;
  String _fullAvatarUrl = '';
  Contact? _selectedContact;

  // 依赖和 BLoC 实例
  final _apiService = ApiService();
  late final ContactsPanelBloc _contactsPanelBloc;
  StreamSubscription? _messageSubscription;

  // 模拟数据
  final List<Conversation> _conversations = [
    Conversation(
      id: "0",
      recipientId: "0",
      avatar: 'assets/image/1.jpg', // 使用您自己的资源路径
      name: 'Flutter 开发者交流群',
      lastMessage: '大佬：BLoC 是 Flutter 的未来！',
      time: '10:30',
      isMuted: true,
      messages: [
        ChatMessage(
            isMe: false,
            sender: '新手小白',
            text: '请问 StatefulWidget 和 StatelessWidget 有什么区别？',
            avatar: 'assets/image/1.jpg'),
        ChatMessage(
            isMe: false,
            sender: '热心群友',
            text: '一个有状态，一个无状态。无状态的 UI 在数据变化时不会自己刷新。',
            avatar: 'assets/image/2.jpg',
            level: 'LV10'),
      ],
    ),
    Conversation(
      id: "2",
      recipientId: "2",
      avatar: 'assets/image/2.jpg',
      name: 'UI 设计师-小雅',
      lastMessage: '[图片]',
      time: '09:15',
      isMuted: false,
      messages: [
        ChatMessage(
            isMe: false,
            sender: 'UI 设计师-小雅',
            text: '这是最新的设计稿，你看下~',
            avatar: 'assets/image/2.jpg'),
        ChatMessage(
            isMe: true,
            sender: '我',
            text: '收到！看起来很棒！',
            avatar: 'assets/image/1.jpg'),
        ChatMessage(
            isMe: false,
            sender: 'UI 设计师-小雅',
            text: '[图片]',
            avatar: 'assets/image/2.jpg'),
      ],
    ),
  ];

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

    // 从环境变量中获取 MQTT Broker 的地址
    // 注意：这个环境变量由 Aspire 通过 `flutter run` 注入
    const mqttServer = String.fromEnvironment(
        'services__mqtt-broker__mqtt__0_host',
        defaultValue: 'localhost');

    _mqttService =
        MqttService(serverAddress: mqttServer, userId: _currentUser!.userId);
    _mqttService!.connect();

    // 监听所有收到的消息
    _messageSubscription = _mqttService!.onMessageReceived.listen((message) {
      // 在这里，您可以根据消息内容更新 UI
      // 例如，找到对应的会话，将新消息添加到它的 messages 列表中
      _handleIncomingMessage(message);
    });
  }

  void _handleIncomingMessage(ChatMessageEvent message) {
    setState(() {
      // 简单的示例逻辑：找到发送者对应的会话并更新
      final targetConversation = _conversations.firstWhere(
        (c) => c.id == message.senderId,
        orElse: () => _conversations.first, // 回退
      );

      final uiMessage = ChatMessage(
        isMe: false,
        sender: message.senderId, // 应该用用户名
        text: message.text,
        avatar: '', // 应该用用户头像
      );

      targetConversation.messages.insert(0, uiMessage);
      targetConversation.lastMessage = message.text;
    });
  }

  @override
  void dispose() {
    _contactsPanelBloc.close(); // 释放 BLoC 资源
    _messageSubscription?.cancel(); // 取消监听
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
    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      body: Column(
        children: [
          CustomTitleBar(avatarUrl: _fullAvatarUrl),
          Expanded(
            child: Row(
              children: [
                LeftNavRail(
                  selectedIndex: _selectedNavIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedNavIndex = index;
                      if (index == 0) {
                        _currentMainState = MainPanelState.chat;
                      } else if (index == 1) {
                        _currentMainState = MainPanelState.contacts;
                        // 切换到联系人主页时，通知 BLoC 清空详情
                        _contactsPanelBloc.add(ClearSelectedContact());
                      }
                    });
                  },
                  avatarUrl: _fullAvatarUrl,
                  onLogout: _logout,
                ),
                BlocProvider.value(
                  value: _contactsPanelBloc,
                  child:
                      _buildMainPanel(), // 现在 _buildMainPanel 及其所有子孙都能访问 BLoC 了
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 总指挥：根据当前状态构建主面板
  /// 总指挥：根据当前状态构建主面板
  Widget _buildMainPanel() {
    switch (_currentMainState) {
      case MainPanelState.chat:
        return Expanded(
          child: Row(
            children: [
              ConversationList(
                conversations: _conversations,
                selectedIndex: _selectedConversationIndex,
                onTap: (index) {
                  setState(() {
                    _selectedConversationIndex = index;
                  });
                },
                onAddFriend: () {
                  setState(() {
                    _selectedNavIndex = 1;
                    _currentMainState = MainPanelState.addFriend;
                  });
                },
              ),
              Expanded(
                child: ChatPanel(
                  conversation: _conversations[_selectedConversationIndex],
                  key: ValueKey(_conversations[_selectedConversationIndex].id),
                  // messages: _conversations[_selectedConversationIndex].messages,
                  mqttService: _mqttService,
                ),
              ),
            ],
          ),
        );

      case MainPanelState.contacts:
      case MainPanelState.friendRequests:
      case MainPanelState.addFriend:
        // 在所有与“联系人”相关的视图下，都使用 BlocBuilder 来构建
        // BlocBuilder 会自动从父级的 BlocProvider 获取 BLoC 实例
        return BlocBuilder<ContactsPanelBloc, ContactsPanelState>(
          builder: (context, contactsState) {
            return Expanded(
              child: Row(
                children: [
                  // 左侧面板：现在是一个 StatelessWidget，完全由 BLoC 驱动
                  ContactsPanel(
                    onAddFriend: () {
                      setState(() {
                        _currentMainState = MainPanelState.addFriend;
                      });
                    },
                    onNavigateToFriendRequests: () {
                      setState(() {
                        _currentMainState = MainPanelState.friendRequests;
                        // 同时通知 BLoC 清除选中联系人
                        context
                            .read<ContactsPanelBloc>()
                            .add(ClearSelectedContact());
                      });
                    },
                    onContactSelected: (Contact value) {},
                  ),

                  // 右侧面板：根据 HomeScreen 的状态和 BLoC 的状态共同决定
                  _buildContactsRightPanel(contactsState),
                ],
              ),
            );
          },
        );
    }
  }

// 构建左侧面板
  Widget _buildLeftPanel() {
    switch (_currentMainState) {
      case MainPanelState.chat:
        // 聊天状态下，左侧是会话列表
        return ConversationList(
          conversations: _conversations,
          selectedIndex: _selectedConversationIndex,
          onTap: (index) {
            setState(() {
              _selectedConversationIndex = index;
            });
          },
          onAddFriend: () {
            // --- 核心修改：点击“+”时，切换到 contacts 状态，并让右侧显示 AddFriendPanel ---
            // 我们通过将 _selectedNavIndex 设为 1 来确保 ContactsPanel 被加载
            // 然后将 _currentMainState 设为 addFriend
            setState(() {
              _selectedNavIndex = 1; // 确保左侧导航栏高亮“联系人”
              _currentMainState = MainPanelState.addFriend;
              _selectedContact = null; // 清空选中的联系人
            });
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
  Widget _buildRightPanel() {
    switch (_currentMainState) {
      case MainPanelState.chat:
        return Expanded(
          child: ChatPanel(
            conversation: _conversations[_selectedConversationIndex],
            // messages: _conversations[_selectedConversationIndex].messages,
          ),
        );

      case MainPanelState.contacts:
        if (_selectedContact == null) {
          return _buildPlaceholder("请从左侧选择一个联系人查看详情");
        } else {
          return ContactDetailPanel(contact: _selectedContact!);
        }

      case MainPanelState.friendRequests:
        return const Expanded(child: FriendRequestsPanel());

      // --- 核心修改：添加这个 case ---
      case MainPanelState.addFriend:
        return const Expanded(child: AddFriendPanel());
      // --------------------------------

      default:
        return _buildPlaceholder("未知状态");
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
      return ContactDetailPanel(contact: state.selectedContact!);
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
