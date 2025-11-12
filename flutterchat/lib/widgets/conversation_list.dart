// lib/widgets/conversation_list.dart
// 用于JSON数据编码（在创建新窗口时传递参数）
// 桌面多窗口支持库：用于创建独立的子窗口（如添加好友的搜索窗口）
import 'package:flutter/material.dart'; // Flutter核心UI组件库
import 'package:flutterchat/widgets/custom_search_field.dart';
import '../models/conversation.dart'; // 会话数据模型（包含会话基本信息）

// 在 conversation_list.dart 文件的顶部
enum ConversationMenuAction { createGroup, addFriend, sendFile }

/// 会话列表组件
/// 展示所有聊天会话的列表，支持选中状态高亮、点击切换会话，以及搜索和添加会话功能
class ConversationList extends StatelessWidget {
  /// 会话数据列表
  /// 存储所有需要展示的会话信息（包含头像、名称、最后一条消息、时间等）
  final List<Conversation> conversations;

  /// 当前选中的会话索引
  /// 用于标记哪个会话被选中，并高亮显示
  final int selectedIndex;

  /// 会话项点击回调
  /// 当点击某个会话时触发，参数为点击的会话索引，用于父组件更新选中状态
  final ValueChanged<int> onTap;
  final VoidCallback? onAddFriend;

  /// 构造函数
  /// 所有参数均为必选，确保组件初始化时能获取到必要的数据和交互逻辑
  const ConversationList({
    super.key,
    required this.conversations,
    required this.selectedIndex,
    required this.onTap,
    this.onAddFriend,
  });

  /// 构建组件UI
  @override
  Widget build(BuildContext context) {
    // 会话列表容器：固定宽度280，深色背景（#3D3D3D），符合聊天应用的深色主题
    return Container(
      width: 280,
      color: const Color(0xFF3D3D3D),
      // 垂直布局：顶部搜索栏 + 下方会话列表
      child: Column(
        children: [
          // 搜索栏区域：包含搜索输入框和添加会话按钮
          Padding(
            padding: const EdgeInsets.all(12.0), // 四周内边距5
            child: Row(
              children: [
                const Expanded(
                  child: CustomSearchField(
                    hintText: '搜索',
                  ),
                ),

                const SizedBox(width: 8), // 搜索框与右侧按钮的间距8
                // 添加会话按钮：点击弹出菜单（创建群聊、加好友等）
                _buildPopupMenuButton(context),
              ],
            ),
          ),
          // 会话列表区域：占满剩余空间，支持滚动（会话过多时可上下滑动）
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length, // 列表项数量 = 会话数据长度
              // 构建每个会话项
              itemBuilder: (context, index) {
                final conversation = conversations[index]; // 当前索引对应的会话数据
                final isSelected = selectedIndex == index; // 判断当前会话是否被选中

                // 可点击容器：点击时触发onTap回调，通知父组件切换选中会话
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    // 会话项内边距：水平12，垂直8，让内容有呼吸感
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    // 背景色：选中时为#4A4A4A（比容器稍浅），未选中时透明（突出选中状态）
                    color: isSelected
                        ? const Color(0xFF4A4A4A)
                        : Colors.transparent,
                    // 会话项内容：水平布局（头像 + 信息区域）
                    child: Row(
                      children: [
                        // 会话头像：圆形，半径22，使用会话数据中的头像路径
                        CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              AssetImage(conversation.avatar), // 本地资源头像
                        ),
                        const SizedBox(width: 10), // 头像与信息区域的间距10
                        // 信息区域：占满剩余空间，垂直布局（名称+时间 / 最后一条消息+静音图标）
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // 左对齐，符合阅读习惯
                            children: [
                              // 第一行：会话名称 + 最后一条消息时间
                              Row(
                                children: [
                                  // 会话名称
                                  Text(
                                    conversation.name,
                                    style: const TextStyle(
                                      color: Colors.white, // 名称颜色白色，突出显示
                                      fontSize: 14, // 名称大小14，清晰可见
                                    ),
                                  ),
                                  const Spacer(), // 填充空间，将时间推至右侧
                                  // 最后一条消息的时间
                                  Text(
                                    conversation.time,
                                    style: const TextStyle(
                                      color: Colors.white54, // 时间颜色半透明，次要信息
                                      fontSize: 12, // 时间大小12，不抢眼
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4), // 两行之间的间距4，区分层级
                              // 第二行：最后一条消息预览 + 静音图标（可选）
                              Row(
                                children: [
                                  // 最后一条消息预览：超出部分显示省略号
                                  Expanded(
                                    child: Text(
                                      conversation.lastMessage,
                                      style: const TextStyle(
                                        color: Colors.white54, // 消息预览半透明，次要信息
                                        fontSize: 13, // 大小13，适配空间
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis, // 文本过长时显示...
                                    ),
                                  ),
                                  // 静音图标：如果会话被静音（isMuted为true），则显示
                                  if (conversation.isMuted)
                                    const Icon(
                                      Icons.notifications_off, // 静音图标
                                      size: 14, // 小尺寸14，不抢眼
                                      color: Colors.white38, // 38%透明白色，更弱化
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带弹出菜单的 "+" 按钮
  /// 点击按钮弹出菜单，包含"创建群聊"、"加好友/群"、"闪传文件"选项
  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<ConversationMenuAction>(
      color: const Color(0xFF2E2E2E), // 菜单背景色（更深的灰色，与主界面区分）
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // 菜单圆角8，增强美观
      ),
      offset: const Offset(0, 40), // 菜单偏移：向右0，向下40，避免遮挡按钮
      onSelected: (ConversationMenuAction value) {
        // <-- 类型改为枚举
        // --- 3. 核心修改：替换这里的逻辑 ---
        if (value == ConversationMenuAction.addFriend) {
          // 不再创建新窗口，而是调用回调函数
          onAddFriend?.call();
        } else {
          debugPrint('选中菜单选项: $value');
        }
        // --------------------------------
      },

      // 菜单选项列表
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<ConversationMenuAction>>[
        _buildPopupMenuItem(
          value: ConversationMenuAction.createGroup, // <-- value 改为枚举
          icon: Icons.add_circle_outline,
          text: '创建群聊',
        ),
        _buildPopupMenuItem(
          value: ConversationMenuAction.addFriend, // <-- value 改为枚举
          icon: Icons.person_add_alt_1_outlined,
          text: '加好友/群',
        ),
        _buildPopupMenuItem(
          value: ConversationMenuAction.sendFile, // <-- value 改为枚举
          icon: Icons.offline_bolt_outlined,
          text: '闪传文件',
        ),
      ],
      // 按钮外观：圆形"+"按钮
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A), // 按钮背景色（与搜索框一致）
          borderRadius: BorderRadius.circular(4), // 圆角4
        ),
        child:
            const Icon(Icons.add, size: 20, color: Colors.white54), // "+"图标，半透明
      ),
    );
  }

  /// 构建单个弹出菜单项
  /// [value]：选项标识（用于onSelected判断）
  /// [icon]：选项图标
  /// [text]：选项文字
  PopupMenuItem<ConversationMenuAction> _buildPopupMenuItem({
    required ConversationMenuAction value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem<ConversationMenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20), // 图标：70%透明白色，大小20
          const SizedBox(width: 12), // 图标与文字间距12
          Text(
            text,
            style:
                const TextStyle(color: Colors.white, fontSize: 14), // 文字白色，大小14
          ),
        ],
      ),
    );
  }
}
