import 'package:flutter/material.dart'; // Flutter核心UI组件库
import 'package:flutterchat/models/auth_response.dart'; // 登录用户信息模型（包含用户ID、头像等）
import 'package:flutterchat/services/api_service.dart'; // API服务（用于处理头像URL构建等）
import 'package:flutterchat/widgets/add_friend_panel.dart';
import '../models/chat_message.dart'; // 聊天消息模型（包含发送者、内容、头像等）
import '../models/contact.dart'; // 联系人模型（包含联系人详细信息）
import '../models/contact_group.dart'; // 联系人分组模型（包含分组名称和联系人列表）
import '../models/conversation.dart'; // 会话模型（包含会话基本信息和消息列表）
import '../widgets/chat_panel.dart'; // 聊天面板组件（显示聊天消息和输入框）
import '../widgets/contacts_panel.dart'; // 联系人面板组件（显示联系人分组和列表）
import '../widgets/conversation_list.dart'; // 会话列表组件（显示所有聊天会话）
import '../widgets/left_nav_rail.dart'; // 左侧导航栏组件（切换聊天/联系人等功能）
import '../widgets/title_bar.dart'; // 自定义标题栏组件（页面顶部标题区域）

enum MainPanelState {
  chat,
  contacts,
  addFriend,
}

/// 首页屏幕组件
/// 作为应用的主界面，包含左侧导航栏、会话列表/联系人列表、聊天面板等核心功能区域
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 左侧导航栏选中索引（0: 聊天，1: 联系人，其他: 未实现功能）
  int _selectedNavIndex = 0;
  // 选中的会话索引（控制当前显示哪个会话的聊天内容）
  int _selectedConversationIndex = 0;

  MainPanelState _currentMainState = MainPanelState.chat;
  // 当前登录用户信息（从登录页传递过来）
  AuthResponse? _currentUser;
  // API服务实例（用于构建头像完整URL等操作）
  final _apiService = ApiService();
  // 当前用户的完整头像URL（通过API服务构建）
  String _fullAvatarUrl = '';

  // --- 聊天消息模拟数据（实际应用中会从API获取） ---
  // "USUSUSUS"会话的消息列表
  static final List<ChatMessage> _messagesForUsusus = [
    ChatMessage(
        isMe: false, // 不是当前用户发送
        sender: '学历姐123', // 发送者昵称
        text: '这里小学生8点半上学, 为什么这么幸福', // 消息内容
        avatar: 'assets/Image/10.jpg', // 发送者头像路径
        level: 'LV88 王者'), // 发送者等级（可选）
    ChatMessage(
        isMe: false,
        sender: 'AAA-初中各科抽象补习-...',
        text: '小学生就是这个点上学啊',
        avatar: 'assets/Image/11.jpg',
        level: 'LV100 管理员'),
    ChatMessage(
        isMe: true, // 当前用户发送
        sender: '我',
        text: '确实，太幸福了！我也想回到那个时候。',
        avatar: 'assets/Image/0.jpg'), // 当前用户头像
    ChatMessage(
        isMe: false,
        sender: 'AAA-初中各科抽象补习-...',
        text: '你穿越了？',
        avatar: 'assets/Image/11.jpg',
        level: 'LV100 管理员'),
  ];

  // "高九复读..."会话的消息列表
  static final List<ChatMessage> _messagesForGaojiu = [
    ChatMessage(
        isMe: false,
        sender: '高九复读...',
        text: '这是发给我的图片',
        avatar: 'assets/Image/2.jpg'),
    ChatMessage(
        isMe: true,
        sender: '我',
        text: '收到了，很清晰。',
        avatar: 'assets/Image/0.jpg'),
  ];

  // "卡2小号"会话的消息列表
  static final List<ChatMessage> _messagesForKa2 = [
    ChatMessage(
        isMe: true,
        sender: '卡2小号12345',
        text: '看这个链接 https://surl.ama...',
        avatar: 'assets/Image/3.jpg'),
  ];

  // --- 会话列表模拟数据（实际应用中会从API获取） ---
  final List<Conversation> _conversations = [
    Conversation(
        avatar: 'assets/Image/1.jpg', // 会话头像
        name: 'USUSUSUS', // 会话名称
        lastMessage: 'AAA-初中各科...', // 最后一条消息预览
        time: '08:33', // 最后一条消息时间
        isMuted: true, // 是否静音
        messages: _messagesForUsusus), // 该会话的消息列表
    Conversation(
        avatar: 'assets/Image/2.jpg',
        name: '高九复读...',
        lastMessage: '[小号1]: [图片]',
        time: '08:14',
        messages: _messagesForGaojiu),
    Conversation(
        avatar: 'assets/Image/3.jpg',
        name: '卡2小号',
        lastMessage: 'https://surl.ama...',
        time: '昨天14:04',
        isMuted: true,
        messages: _messagesForKa2),
    Conversation(
        avatar: 'assets/Image/4.jpg',
        name: 'BKTV',
        lastMessage: '【来自未来的英...',
        time: '星期日',
        messages: []),
    Conversation(
      avatar: 'assets/Image/5.jpg',
      name: '<打印店>',
      lastMessage: '对方已成功接收...',
      time: '10/17',
      messages: [
        ChatMessage(
            isMe: false,
            sender: '<打印店>',
            text: '文件已打印',
            avatar: 'assets/Image/5.jpg')
      ],
    ),
    Conversation(
        avatar: 'assets/Image/6.jpg',
        name: '电脑小号',
        lastMessage: '肖邦升c小调幻想...',
        time: '09/30',
        messages: [
          ChatMessage(
              isMe: false,
              sender: '<打印店>',
              text: '文件已打印',
              avatar: 'assets/Image/8.jpg')
        ]),
  ];

  // --- 联系人模拟数据（实际应用中会从API获取） ---
  // 联系人1：Kitaya
  static final Contact contact1 = Contact(
    avatar: 'assets/image/20.jpg', // 联系人头像
    name: 'Kitaya', // 联系人名称
    qqNumber: '3303545220', // QQ号
    statusText: '听歌中', // 状态文本
    statusIcon: Icons.music_note, // 状态图标（音乐图标表示正在听歌）
    statusIconColor: Colors.orange, // 状态图标颜色
    gender: '男', // 性别
    age: 25, // 年龄
    birthday: '6月20日', // 生日
    constellation: '双子座', // 星座
    remark: '东海帝皇official...', // 备注
    groupName: '《高中美男团》', // 所属分组
    signature: '花园在召唤你', // 个性签名
    photos: [
      'assets/Image/2.jpg',
      'assets/Image/5.jpg',
      'assets/Image/8.jpg'
    ], // 相册（暂为空）
  );

  // 联系人2：Eijun
  static final Contact contact2 = Contact(
    avatar: 'assets/Image/30.jpg',
    name: 'Eijun',
    qqNumber: '1234567890',
    statusText: '在线',
    statusIcon: Icons.circle, // 圆形图标表示在线
    statusIconColor: Colors.green, // 绿色表示在线
    gender: '男',
    age: 18,
    birthday: '5月15日',
    constellation: '金牛座',
    remark: '【英俊潇洒-坤...',
    groupName: '《高中美男团》',
    signature: 'Catch the dream!',
    photos: [],
  );

  // 联系人分组列表
  final List<ContactGroup> _contactGroups = [
    ContactGroup(name: '我的设备', contacts: []), // 分组名称 + 联系人列表
    ContactGroup(name: '特别关心', contacts: []),
    ContactGroup(name: '【ε-世界线】', contacts: []),
    ContactGroup(name: '【β-世界线】', contacts: []),
    ContactGroup(name: '【γ-世界线】', contacts: []),
    ContactGroup(name: '【λ-世界线】', contacts: []),
    ContactGroup(name: '【Asshole的大...', contacts: []),
    ContactGroup(name: '《高中美男团》', contacts: [contact1, contact2]), // 包含2个联系人
  ];

  /// 依赖变化时调用（如路由参数更新）
  /// 从登录页传递的参数中获取当前用户信息，并构建完整头像URL
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取路由参数（登录成功后传递的AuthResponse对象）
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AuthResponse) {
      setState(() {
        _currentUser = args; // 保存当前用户信息
        // 通过API服务构建完整的头像URL（结合MinIO地址和对象标识）
        _fullAvatarUrl = _apiService.getFullAvatarUrl(_currentUser?.avatarUrl);
      });
    }
  }

  /// 构建首页UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF363636), // 深灰色背景（符合聊天应用深色主题）
      body: Column(
        children: [
          const CustomTitleBar(), // 顶部自定义标题栏（显示应用名称、搜索等）
          Expanded(
            // 填充剩余空间（包含左侧导航和主内容区）
            child: Row(
              children: [
                // 左侧导航栏（切换聊天/联系人等功能）
                LeftNavRail(
                  selectedIndex: _selectedNavIndex, // 当前选中的导航项
                  onDestinationSelected: (index) {
                    // 导航项选中回调
                    setState(() {
                      _selectedNavIndex = index;
                      if (index == 0) {
                        _currentMainState = MainPanelState.chat;
                      } else if (index == 1) {
                        _currentMainState = MainPanelState.contacts;
                      }
                    });
                  },
                  avatarUrl: _fullAvatarUrl, // 当前用户头像URL（显示在导航栏顶部）
                ),
                _buildMainPanel(), // 主内容面板（根据导航选中项显示不同内容）
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 一个更清晰、更正确的 _buildMainPanel 版本 ---
  Widget _buildMainPanel() {
    switch (_currentMainState) {
      case MainPanelState.chat:
        // 聊天状态：左侧会话列表 + 右侧聊天面板
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
                    _currentMainState = MainPanelState.addFriend;
                  });
                },
              ),
              Expanded(
                child: ChatPanel(
                  conversation: _conversations[_selectedConversationIndex],
                  messages: _conversations[_selectedConversationIndex].messages,
                ),
              ),
            ],
          ),
        );
      case MainPanelState.contacts:
        // 联系人状态：整个区域都是 ContactsPanel
        return Expanded(
          child: ContactsPanel(contactGroups: _contactGroups),
        );
      case MainPanelState.addFriend:
        // 添加好友状态：整个区域都是 AddFriendPanel
        return const Expanded(
          child: AddFriendPanel(),
        );
    }
  }

  // 辅助方法：构建左侧的列表面板

  // 辅助方法：构建右侧的核心内容面板
}
