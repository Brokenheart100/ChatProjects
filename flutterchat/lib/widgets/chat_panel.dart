import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/chat_ui_provider.dart';
import 'package:flutterchat/providers/user_profile_provider.dart';
import 'package:flutterchat/services/logger_service.dart'; // ✅ 引入 Logger
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/chat_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutterchat/widgets/group_right_panel.dart'; // 引入刚才创建的组件

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
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    logger.i(
        "🎨 [ChatPanel] 初始化: ${widget.conversation.name} (UUID: ${widget.conversation.uuid}, isGroup: ${widget.conversation.isGroup})");
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    logger.i("📤 [ChatPanel] 发送文本: $text");
    ref
        .read(chatProvider(
                widget.conversation.uuid, widget.conversation.recipientId)
            .notifier)
        .sendText(text);
    _textController.clear();
  }

  void _onImagePressed() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        _sendImageFile(pickedFile);
      }
    } catch (e) {
      debugPrint("图片选择失败: $e");
    }
  }

  // ✅ 提取发送图片的公共方法
  void _sendImageFile(XFile file) {
    ref
        .read(chatProvider(
                widget.conversation.uuid, widget.conversation.recipientId)
            .notifier)
        .sendImage(file);
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    final notifier = ref.read(
        chatProvider(widget.conversation.uuid, widget.conversation.recipientId)
            .notifier);

    for (final file in files) {
      // 简单判断文件扩展名
      final ext = file.name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        logger.i("📤 [Drop] 检测到图片，准备发送: ${file.path}");
        notifier.sendImage(file);
      } else {
        // TODO: 后续支持发送普通文件 (FileApi)
        logger.w("⚠️ [Drop] 不支持的文件类型: $ext");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("暂不支持发送 $ext 文件"),
                backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.userId ?? '';
    final showSidebar = ref.watch(showGroupSidebarProvider);
    // 判断是否是群聊
    final isGroup = widget.conversation.isGroup;
    final chatAsyncValue = ref.watch(chatProvider(
        widget.conversation.uuid, widget.conversation.recipientId));

    // 监听错误
    ref.listen(
        chatProvider(widget.conversation.uuid, widget.conversation.recipientId),
        (previous, next) {
      if (next is AsyncError) {
        logger.e("❌ [ChatPanel] Provider 发生错误: ${next.error}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("发生错误: ${next.error}"),
              backgroundColor: Colors.red),
        );
      }
    });

    // ✅ 4. 使用 DropTarget 包裹整个界面
    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(details.files);
      },
      child: Stack(
        children: [
          // 原有内容
          Row(
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFF333333),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: chatAsyncValue.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(
                              child: Text('加载失败: $err',
                                  style:
                                      const TextStyle(color: Colors.white54))),
                          data: (messages) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
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
                ),
              ),
              if (isGroup)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: showSidebar ? 240 : 0, // 通过宽度控制折叠
                  child: ClipRect(
                    // 防止内容溢出
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: 240,
                      alignment: Alignment.topLeft,
                      child: GroupRightPanel(groupId: widget.conversation.uuid),
                    ),
                  ),
                ),
            ],
          ),

          // ✅ 5. 拖拽时的覆盖层 (Overlay)
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(77),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          size: 60, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        "松开鼠标发送图片",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // 获取侧边栏开关状态
    final showSidebar = ref.watch(showGroupSidebarProvider);
    // 判断是否是群聊
    final isGroup = widget.conversation.isGroup;
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
          if (isGroup) ...[
            const SizedBox(width: 8),
            Text("(${widget.conversation.id})", // 这里可以显示人数，需从GroupDetail获取
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70, size: 20),
            tooltip: "搜索历史消息",
            onPressed: () {
              // 跳转到搜索页，传递当前会话ID
              // 注意：你需要把 SearchPage 注册到 router.dart 中
              context
                  .push('/search?conversationId=${widget.conversation.uuid}');
            },
          ),
          const SizedBox(width: 16),
          const Icon(Icons.call, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          const Icon(Icons.videocam, color: Colors.white70, size: 20),
          const SizedBox(width: 16),
          if (isGroup)
            IconButton(
              icon: Icon(
                showSidebar ? Icons.last_page : Icons.first_page, // 图标随状态变化
                color: showSidebar ? const Color(0xFF6584FE) : Colors.white70,
              ),
              tooltip: "群成员/公告",
              onPressed: () {
                // 切换状态
                ref.read(showGroupSidebarProvider.notifier).state =
                    !showSidebar;
              },
            ),
          if (!isGroup) // 私聊保持原来的更多按钮
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                context.push(
                    '/chat/user-profile/${widget.conversation.recipientId}');
              },
            ),
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
    )
        .animate()
        .fade(duration: 300.ms)
        .moveX(begin: 30, end: 0, curve: Curves.easeOutBack)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _buildOthersMessage(ChatMessage message) {
    // 1. 私聊场景
    if (!widget.conversation.isGroup) {
      final bool hasAvatar =
          message.avatar != null && message.avatar!.isNotEmpty;

      final displayAvatar =
          hasAvatar ? message.avatar : widget.conversation.avatar;

      return _buildMessageRow(
        message,
        displayName: "",
        avatarUrl: displayAvatar,
        showName: false,
      );
    }

    // 2. 群聊场景 (使用 Provider)
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(userProfileProvider(message.senderId));

        return userAsync.when(data: (user) {
          // 🔍 调试日志：打印渲染信息
          logger
              .d("👤 [ChatPanel] 渲染群友: ${user.username} (ID: ${user.userId})");
          return _buildMessageRow(
            message,
            displayName: user.username,
            avatarUrl: user.avatarUrl,
            showName: true,
          );
        }, loading: () {
          logger.d("⏳ [ChatPanel] 正在加载群友资料: ${message.senderId}");
          return _buildMessageRow(message,
              displayName: "...", avatarUrl: '', showName: true);
        }, error: (e, s) {
          logger.e("❌ [ChatPanel] 群友资料加载失败: ${message.senderId}", error: e);
          return _buildMessageRow(message,
              displayName: "未知用户", avatarUrl: '', showName: true);
        });
      },
    );
  }

  Widget _buildMessageRow(ChatMessage message,
      {required String displayName,
      required String? avatarUrl,
      required bool showName}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCircleAvatar(
            avatarUrl: avatarUrl,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showName) ...[
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                ],
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
    )
        .animate()
        .fade(duration: 300.ms)
        .moveX(begin: -30, end: 0, curve: Curves.easeOutBack)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
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
