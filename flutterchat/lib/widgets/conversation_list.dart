// lib/widgets/conversation_list.dart

import 'dart:convert';
// --- 核心修复：添加下面这行 import 语句 ---
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import '../models/conversation.dart';

// 会话列表组件，继承无状态组件StatelessWidget
// 用于展示聊天会话列表，支持选中状态和点击交互
class ConversationList extends StatelessWidget {
  // 会话数据列表：存储所有需要展示的会话信息（包含头像、名称、最后一条消息等）
  final List<Conversation> conversations;
  // 当前选中的会话索引：用于高亮显示选中的会话项
  final int selectedIndex;
  // 点击会话项时的回调函数：参数为点击的会话索引，用于更新选中状态或跳转详情
  final ValueChanged<int> onTap;

  // 构造函数：接收会话列表、选中索引和点击回调，均为必选参数
  const ConversationList({
    super.key,
    required this.conversations,
    required this.selectedIndex,
    required this.onTap,
  });

  // 构建组件UI
  @override
  Widget build(BuildContext context) {
    // 会话列表容器：固定宽度280，背景色为深灰色（#3D3D3D）
    return Container(
      width: 280,
      color: const Color(0xFF3D3D3D),
      // 垂直布局：包含搜索栏和会话列表两部分
      child: Column(
        children: [
          // 搜索栏区域
          Padding(
            padding: const EdgeInsets.all(12.0), // 四周内边距12
            child: Row(
              children: [
                // 搜索输入框：占满剩余空间
                Expanded(
                  child: Container(
                    height: 32, // 输入框高度32
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A4A), // 输入框背景色（深灰偏浅）
                      borderRadius: BorderRadius.circular(4), // 圆角4
                    ),
                    child: const TextField(
                      style: TextStyle(
                        color: Colors.white, // 输入文本颜色白色
                        fontSize: 13, // 输入文本大小13
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索', // 提示文本
                        hintStyle: TextStyle(
                          color: Colors.white54, // 提示文本颜色半透明白色
                          fontSize: 13, // 提示文本大小13
                        ),
                        prefixIcon: Icon(
                          Icons.search, // 前缀搜索图标
                          size: 16, // 图标大小16
                          color: Colors.white54, // 图标颜色半透明白色
                        ),
                        border: InputBorder.none, // 取消默认边框
                        contentPadding: EdgeInsets.only(
                          bottom: 12,
                        ), // 底部内边距12（调整文字垂直居中）
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // 搜索框与右侧按钮的间距8
                // 添加会话按钮：圆形图标按钮
                _buildPopupMenuButton(context),
              ],
            ),
          ),
          // 会话列表区域：占满剩余空间，支持滚动
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length, // 列表项数量=会话数据长度
              // 构建每个会话项
              itemBuilder: (context, index) {
                final conversation = conversations[index]; // 当前索引对应的会话数据
                final isSelected = selectedIndex == index; // 判断当前项是否为选中状态

                // 可点击容器：点击时触发onTap回调，传入当前索引
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    // 会话项内边距：水平12，垂直8
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    // 背景色：选中时为#4A4A4A（深灰偏浅），未选中时透明
                    color: isSelected
                        ? const Color(0xFF4A4A4A)
                        : Colors.transparent,
                    // 会话项内容：水平布局（头像+信息区域）
                    child: Row(
                      children: [
                        // 会话头像：圆形，半径22，使用会话数据中的头像路径
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(conversation.avatar),
                        ),
                        const SizedBox(width: 10), // 头像与信息区域的间距10
                        // 信息区域：占满剩余空间，垂直布局（名称+时间 / 最后一条消息+静音图标）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                            children: [
                              // 第一行：名称和时间
                              Row(
                                children: [
                                  // 会话名称
                                  Text(
                                    conversation.name,
                                    style: const TextStyle(
                                      color: Colors.white, // 名称颜色白色
                                      fontSize: 14, // 名称大小14
                                    ),
                                  ),
                                  const Spacer(), // 填充空间，将时间推至右侧
                                  // 消息时间
                                  Text(
                                    conversation.time,
                                    style: const TextStyle(
                                      color: Colors.white54, // 时间颜色半透明白色
                                      fontSize: 12, // 时间大小12
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4), // 两行之间的间距4
                              // 第二行：最后一条消息和静音图标
                              Row(
                                children: [
                                  // 最后一条消息：超出部分显示省略号
                                  Expanded(
                                    child: Text(
                                      conversation.lastMessage,
                                      style: const TextStyle(
                                        color: Colors.white54, // 消息颜色半透明白色
                                        fontSize: 13, // 消息大小13
                                      ),
                                      overflow:
                                          TextOverflow.ellipsis, // 文本溢出时显示省略号
                                    ),
                                  ),
                                  // 静音图标：如果会话静音（isMuted为true），则显示
                                  if (conversation.isMuted)
                                    const Icon(
                                      Icons.notifications_off, // 静音图标
                                      size: 14, // 图标大小14
                                      color: Colors.white38, // 图标颜色38%透明白色
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

  // 构建带弹出菜单的 "+" 按钮
  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      offset: const Offset(0, 40),
      onSelected: (value) async {
        if (value == 'add_friend') {
          try {
            final args = jsonEncode({'window_type': 'search'}); // JSON 参数
            final controller = await WindowController.create(
              WindowConfiguration(
                hiddenAtLaunch: true, // 隐藏启动，待 main() 配置后显示
                arguments: args, // 传递参数给新窗口的 main()
              ),
            );
            await controller.show(); // 显示窗口，触发配置
            debugPrint('搜索窗口创建并显示成功');
          } catch (e) {
            debugPrint('创建窗口失败: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('打开搜索失败: $e')),
              );
            }
          }
        } else {
          debugPrint('选中: $value'); // 替换 print，修复警告
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(
          value: 'create_group',
          icon: Icons.add_circle_outline,
          text: '创建群聊',
        ),
        _buildPopupMenuItem(
          value: 'add_friend',
          icon: Icons.person_add_alt_1_outlined,
          text: '加好友/群',
        ),
        _buildPopupMenuItem(
          value: 'send_file',
          icon: Icons.offline_bolt_outlined,
          text: '闪传文件',
        ),
      ],
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, size: 20, color: Colors.white54),
      ),
    );
  }

  // 构建单个菜单项
  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String text,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
