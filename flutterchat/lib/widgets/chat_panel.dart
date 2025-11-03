// 导入Flutter Material组件库，用于构建聊天面板的UI界面
import 'package:flutter/material.dart';
// 导入聊天消息数据模型，存储单条聊天消息的信息（如发送者、内容、头像等）
import '../models/chat_message.dart';
// 导入会话数据模型，存储当前聊天会话的基础信息（如会话名称）
import '../models/conversation.dart';

// 聊天面板核心组件，继承无状态组件StatelessWidget
// 负责展示聊天头部、消息列表、消息输入区域三大模块
class ChatPanel extends StatelessWidget {
  // 当前聊天的会话信息：用于获取会话名称等基础数据
  final Conversation conversation;
  // 当前会话的消息列表：用于展示所有聊天消息
  final List<ChatMessage> messages;

  // 构造函数：接收会话信息和消息列表，均为必选参数
  const ChatPanel({
    super.key,
    required this.conversation,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    // 聊天面板主容器：背景为深灰色（#333333）+ 半透明聊天背景图
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        image: DecorationImage(
          image: AssetImage('assets/chat_bg.png'), // 聊天背景图资源路径
          fit: BoxFit.cover, // 背景图铺满容器
          opacity: 0.1, // 背景图透明度（避免遮挡前景内容）
        ),
      ),
      // 垂直布局：依次排列「聊天头部」「消息列表」「消息输入区」
      child: Column(
        children: [
          // 1. 聊天头部（显示会话名称、功能按钮）
          Container(
            height: 50, // 头部固定高度50
            padding: const EdgeInsets.symmetric(horizontal: 20), // 水平内边距20
            // 头部下边框：黑色半透明（分割头部与消息列表）
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black26, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // 会话名称 + 人数标记（示例：“XXX (12)”）
                Text(
                  '${conversation.name} (12)', // 拼接会话名称与人数
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(), // 填充空间，将右侧功能图标推至最右端
                // 通话功能图标
                const Icon(Icons.call, color: Colors.white70, size: 20),
                const SizedBox(width: 16), // 图标间距16
                // 视频通话功能图标
                const Icon(Icons.videocam, color: Colors.white70, size: 20),
                const SizedBox(width: 16), // 图标间距16
                // 屏幕共享功能图标
                const Icon(Icons.screen_share, color: Colors.white70, size: 20),
                const SizedBox(width: 16), // 图标间距16
                // 更多功能图标（如会话设置等）
                const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
              ],
            ),
          ),

          // 2. 消息列表区域（占满剩余垂直空间，支持滚动）
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                // 根据 message.isMe 决定调用哪个布局方法
                if (message.isMe) {
                  return _buildMyMessage(context, message);
                } else {
                  return _buildOthersMessage(context, message);
                }
              },
            ),
          ),
          // 3. 消息输入区域（固定高度150，深色背景）
          Container(
            height: 150,
            color: const Color(0xFF3D3D3D),
            // 垂直布局：输入工具图标行 + 输入框 + 发送按钮
            child: Column(
              children: [
                // 3.1 输入工具图标行（表情、图片、麦克风等）
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, // 水平内边距12
                    vertical: 8.0, // 垂直内边距8
                  ),
                  child: Row(
                    children: [
                      _buildInputToolIcon(
                        Icons.emoji_emotions_outlined,
                      ), // 表情图标
                      _buildInputToolIcon(Icons.cut), // 剪切（或文件）图标
                      _buildInputToolIcon(Icons.vibration), // 震动（或特效）图标
                      _buildInputToolIcon(Icons.image_outlined), // 图片图标
                      _buildInputToolIcon(Icons.mic_none), // 麦克风图标
                      const Spacer(), // 填充空间，将历史图标推至右端
                      _buildInputToolIcon(Icons.history), // 历史记录图标
                    ],
                  ),
                ),

                // 3.2 消息输入框（占满剩余高度，支持多行输入）
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0), // 水平内边距16
                    child: TextField(
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ), // 输入文本样式
                      maxLines: null, // 取消最大行数限制（支持自动换行）
                      decoration: InputDecoration(
                        border: InputBorder.none, // 取消默认边框
                        hintText: '', // 空提示文本（可根据需求修改）
                      ),
                    ),
                  ),
                ),

                // 3.3 发送按钮（靠右对齐，蓝色背景）
                Padding(
                  padding: const EdgeInsets.all(8.0), // 四周内边距8
                  child: Align(
                    alignment: Alignment.centerRight, // 右对齐
                    child: ElevatedButton(
                      onPressed: () {}, // 点击事件（暂为空实现）
                      // 按钮样式
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6584FE,
                        ), // 蓝色背景（#6584FE）
                        foregroundColor: Colors.white, // 文本白色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 圆角4
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, // 水平内边距24
                          vertical: 12, // 垂直内边距12
                        ),
                      ),
                      child: const Text('发送'), // 按钮文本
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建他人消息（左对齐）
  Widget _buildOthersMessage(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundImage: AssetImage(message.avatar)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    message.sender,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  if (message.level.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        message.level,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: message.text.contains("幸福")
                      ? const Color(0xFF6E8B49)
                      : const Color(0xFF434343),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建我的消息（右对齐）
  Widget _buildMyMessage(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 关键：主轴末端对齐
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息气泡在头像左边
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6584FE), // 我的消息使用不同的颜色
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(backgroundImage: AssetImage(message.avatar)),
        ],
      ),
    );
  }

  // 私有方法：构建消息输入区的工具图标按钮（统一样式）
  // 参数：icon - 图标数据（如Icons.emoji_emotions_outlined）
  Widget _buildInputToolIcon(IconData icon) {
    return IconButton(
      onPressed: () {}, // 图标点击事件（暂为空实现）
      icon: Icon(
        icon,
        color: Colors.white70, // 图标颜色：半透明白色
        size: 22, // 图标大小22
      ),
    );
  }
}
