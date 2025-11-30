import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/user_profile_provider.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/chat_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';

class ChatPanel extends ConsumerStatefulWidget {
  final Conversation conversation;

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

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatProvider(
                widget.conversation.uuid, // ✅ 修改点：使用 uuid (String)
                widget.conversation.recipientId)
            .notifier)
        .sendText(text);
    _textController.clear();
  }

  void _onImagePressed() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        ref
            .read(chatProvider(
                    widget.conversation.uuid, // ✅ 修改点：使用 uuid
                    widget.conversation.recipientId)
                .notifier)
            .sendImage(pickedFile);
      }
    } catch (e) {
      debugPrint("图片选择失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.userId ?? '';
    // ✅ 修改点：使用 uuid
    final chatAsyncValue = ref.watch(chatProvider(
        widget.conversation.uuid, widget.conversation.recipientId));

    // ✅ 修改点：使用 uuid
    ref.listen(
        chatProvider(widget.conversation.uuid, widget.conversation.recipientId),
        (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("发生错误: ${next.error}"),
              backgroundColor: Colors.red),
        );
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        image: DecorationImage(
          image: AssetImage('assets/Image/28.jpg'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: chatAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text('加载失败: $err',
                      style: const TextStyle(color: Colors.white54))),
              data: (messages) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId.toLowerCase() ==
                        currentUserId.toLowerCase();
                    return isMe
                        ? _buildMyMessage(message)
                        : _buildOthersMessage(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6584FE),
                ),
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
          CustomCircleAvatar(
            avatarUrl: message.avatar,
            radius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildOthersMessage(ChatMessage message) {
    // ------------------------------------------------------
    // 场景 A: 私聊
    // ------------------------------------------------------
    if (!widget.conversation.isGroup) {
      // 私聊直接显示头像，不需要显示名字（或者名字就是会话名）
      // 如果消息里没带头像，就用会话头像（对方头像）兜底
      final displayAvatar = message.avatar.isNotEmpty
          ? message.avatar
          : widget.conversation.avatar;

      return _buildMessageRow(
        message,
        displayName: "", // 私聊通常不显示名字，如果想显示就传 widget.conversation.name
        avatarUrl: displayAvatar,
        showName: false, // 私聊隐藏名字栏
      );
    }

    // ------------------------------------------------------
    // 场景 B: 群聊 (核心修复)
    // ------------------------------------------------------
    // 必须使用 Consumer 去监听 UserProfileProvider，根据 senderId 查名字
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(userProfileProvider(message.senderId));

        return userAsync.when(
          // 1. 查到了：显示真实昵称和头像
          data: (user) => _buildMessageRow(
            message,
            displayName: user.username,
            avatarUrl: user.avatarUrl,
            showName: true,
          ),
          // 2. 加载中：显示 Loading 占位
          loading: () => _buildMessageRow(
            message,
            displayName: "...",
            avatarUrl: "",
            showName: true,
          ),
          // 3. 出错/没查到：显示 ID 或未知
          error: (_, __) => _buildMessageRow(
            message,
            displayName: "未知用户", // 或者 message.senderId
            avatarUrl: "",
            showName: true,
          ),
        );
      },
    );
  }

  /// ✅ 提取出来的通用构建方法 (避免代码重复)
  Widget _buildMessageRow(
    ChatMessage message, {
    required String displayName,
    required String? avatarUrl,
    required bool showName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          CustomCircleAvatar(
            avatarUrl: avatarUrl,
            radius: 18,
          ),
          const SizedBox(width: 12),

          // 内容区域
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 仅在群聊显示名字
                if (showName) ...[
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
                // 气泡
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    if (message.contentType == 1) {
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
