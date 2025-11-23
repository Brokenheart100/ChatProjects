import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. 引入 Riverpod
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
// 引入我们生成的 ChatProvider (确保你运行了 build_runner)
import 'package:flutterchat/providers/chat_provider.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 用于获取 apiService

// 2. 改为继承 ConsumerStatefulWidget
// 我们依然需要 Stateful 是因为 TextEditingController 和 ScrollController 需要 dispose
class ChatPanel extends ConsumerStatefulWidget {
  final Conversation conversation;

  // 注意：移除了 mqttService 和 currentUserId 参数
  // 因为 Riverpod Provider 会自动从全局状态中获取这些信息，不需要层层传递
  const ChatPanel({
    super.key,
    required this.conversation,
  });

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 发送文本逻辑
  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Riverpod 调用方式：
    // ref.read(provider.notifier).method()
    ref.read(chatProvider(widget.conversation.id).notifier).sendText(text);

    _textController.clear();
  }

  // 发送图片逻辑
  void _onImagePressed() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        ref
            .read(chatProvider(widget.conversation.id).notifier)
            .sendImage(pickedFile);
      }
    } catch (e) {
      debugPrint("图片选择失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. 监听数据状态 (AsyncValue)
    // 当 conversation.id 变化时，Riverpod 会自动切换到对应的 Provider 实例
    final chatAsyncValue = ref.watch(chatProvider(widget.conversation.id));

    // 4. 监听错误事件 (替代 BlocListener)
    // 如果 Provider 状态变为 Error (例如发送失败)，在这里处理
    ref.listen(chatProvider(widget.conversation.id), (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("发生错误: ${next.error}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        image: DecorationImage(
          image: AssetImage('assets/Image/27.jpg'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(),

          // 消息列表区域
          Expanded(
            // 5. AsyncValue 优雅处理 加载/错误/数据 三种状态
            child: chatAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text('加载失败: $err',
                      style: const TextStyle(color: Colors.white54))),
              data: (messages) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  reverse: true, // 倒序排列，最新消息在底部
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return message.isMe
                        ? _buildMyMessage(message)
                        : _buildOthersMessage(message);
                  },
                );
              },
            ),
          ),

          // 输入框区域
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- UI 构建辅助方法 ---

  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black26, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            widget.conversation.name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          const Icon(Icons.call, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          const Icon(Icons.videocam, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      height: 150,
      color: const Color(0xFF3D3D3D),
      child: Column(
        children: [
          // 工具栏
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                _buildInputToolIcon(Icons.emoji_emotions_outlined, () {}),
                _buildInputToolIcon(Icons.image_outlined, _onImagePressed),
                _buildInputToolIcon(Icons.mic_none, () {}),
              ],
            ),
          ),
          // 输入框
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _onSendPressed(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'input',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),
          // 发送按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6584FE),
                ),
                // 这里其实可以进一步优化：如果处于发送中状态，显示转圈
                // 但需要从 Provider 状态中获取 isSending，AsyncValue 本身不包含这个业务状态
                // 简单起见，我们先只显示文字
                child: const Text('发送'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputToolIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: 22),
    );
  }

  Widget _buildMyMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6584FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildMessageContent(message),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundImage: AssetImage(message.avatar.isNotEmpty
                ? message.avatar
                : 'assets/image/42.jpg'),
          ),
        ],
      ),
    );
  }

  Widget _buildOthersMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(message.avatar.isNotEmpty
                ? message.avatar
                : 'assets/image/default.png'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF434343),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildMessageContent(message),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    if (message.contentType == 1) {
      // 使用 Riverpod 获取 ApiService 实例来生成 URL
      // 注意：在 ConsumerState 中，我们不能直接 ref.read(apiServiceProvider).getFullAvatarUrl
      // 最好是把 getFullAvatarUrl 变成静态方法，或者通过 ref 读出来
      final apiService = ref.read(apiServiceProvider);
      final fullUrl = apiService.getFullAvatarUrl(message.text);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      );
    }
  }
}
