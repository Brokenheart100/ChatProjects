import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../models/conversation.dart';
import '../widgets/chat_panel.dart';
import '../widgets/contacts_panel.dart';
import '../widgets/conversation_list.dart';
import '../widgets/left_nav_rail.dart';
import '../widgets/title_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedConversationIndex = 0;

  // --- Data for Chat View with CORRECTED asset paths ---
  static final List<ChatMessage> _messagesForUsusus = [
    ChatMessage(
        isMe: false,
        sender: '学历姐',
        text: '这里小学生8点半上学, 为什么这么幸福',
        avatar: 'assets/Image/10.jpg',
        level: 'LV88 王者'),
    ChatMessage(
        isMe: false,
        sender: 'AAA-初中各科抽象补习-...',
        text: '小学生就是这个点上学啊',
        avatar: 'assets/Image/11.jpg',
        level: 'LV100 管理员'),
    ChatMessage(
        isMe: true,
        sender: '我',
        text: '确实，太幸福了！我也想回到那个时候。',
        avatar: 'assets/Image/0.jpg'), // Your avatar
    ChatMessage(
        isMe: false,
        sender: 'AAA-初中各科抽象补习-...',
        text: '你穿越了？',
        avatar: 'assets/Image/11.jpg',
        level: 'LV100 管理员'),
  ];
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
        avatar: 'assets/Image/0.jpg'), // Your avatar
  ];
  static final List<ChatMessage> _messagesForKa2 = [
    ChatMessage(
        isMe: false,
        sender: '卡2小号',
        text: '看这个链接 https://surl.ama...',
        avatar: 'assets/Image/3.jpg'),
  ];

  final List<Conversation> _conversations = [
    Conversation(
        avatar: 'assets/Image/1.jpg',
        name: 'USUSUSUS',
        lastMessage: 'AAA-初中各科...',
        time: '08:33',
        isMuted: true,
        messages: _messagesForUsusus),
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
        messages: []),
  ];

  // --- Data for Contacts View with CORRECTED asset paths ---
  static final Contact contact1 = Contact(
    avatar: 'assets/image/20.jpg', // Using one of your images for the contact
    name: 'Kitaya',
    qqNumber: '3303545220',
    statusText: '听歌中',
    statusIcon: Icons.music_note,
    statusIconColor: Colors.orange,
    gender: '男',
    age: 25,
    birthday: '6月20日',
    constellation: '双子座',
    remark: '东海帝皇official...',
    groupName: '《高中美男团》',
    signature: '花园在召唤你',
    photos: [
      // Using your numbered images for the photo gallery
      // 'assets/image/21.jpg', 'assets/Image/22.jpg', 'assets/Image/23.jpg',
      // 'assets/Image/24.jpg', 'assets/Image/25.jpg', 'assets/Image/26.jpg',
    ],
  );

  static final Contact contact2 = Contact(
    avatar: 'assets/Image/30.jpg', // Using another image
    name: 'Eijun',
    qqNumber: '1234567890',
    statusText: '在线',
    statusIcon: Icons.circle,
    statusIconColor: Colors.green,
    gender: '男',
    age: 18,
    birthday: '5月15日',
    constellation: '金牛座',
    remark: '【英俊潇洒-坤...',
    groupName: '《高中美男团》',
    signature: 'Catch the dream!',
    photos: [],
  );

  final List<ContactGroup> _contactGroups = [
    ContactGroup(name: '我的设备', contacts: []),
    ContactGroup(name: '特别关心', contacts: []),
    ContactGroup(name: '【ε-世界线】', contacts: []),
    ContactGroup(name: '【β-世界线】', contacts: []),
    ContactGroup(name: '【γ-世界线】', contacts: []),
    ContactGroup(name: '【λ-世界线】', contacts: []),
    ContactGroup(name: '【Asshole的大...', contacts: []),
    ContactGroup(name: '《高中美男团》', contacts: [contact1, contact2]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      body: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: Row(
              children: [
                LeftNavRail(
                  selectedIndex: _selectedNavIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                  },
                ),
                _buildMainPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPanel() {
    switch (_selectedNavIndex) {
      case 0:
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
      case 1:
        return Expanded(child: ContactsPanel(contactGroups: _contactGroups));
      default:
        return Expanded(child: Container(color: const Color(0xFF54514E)));
    }
  }
}
