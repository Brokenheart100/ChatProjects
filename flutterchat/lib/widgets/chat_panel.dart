// 导入Flutter Material组件库，用于构建聊天面板的UI界面
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterchat/bloc/chat/chat_bloc.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:image_picker/image_picker.dart';
// 导入聊天消息数据模型，存储单条聊天消息的信息（如发送者、内容、头像等）
import '../models/chat_message.dart';
// 导入会话数据模型，存储当前聊天会话的基础信息（如会话名称）
import '../models/conversation.dart';

class ChatPanel extends StatelessWidget {
  final Conversation conversation;
  final MqttService? mqttService;
  final String currentUserId;
  // 2. 移除构造函数前的 const
  const ChatPanel({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.mqttService,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 在这里注入 ChatBloc
    // 使用 key 确保切换会话时 Bloc 会重建
    return BlocProvider(
      key: ValueKey(conversation.id),
      create: (context) => ChatBloc(
        apiService: ApiService(), // 暂时这里还 new，等做 Step 2 改单例
        mqttService: mqttService,
        conversationId: conversation.id,
        currentUserId: currentUserId,
      )..add(ChatStarted()), // 创建时立即触发加载事件
      child: ChatPanelView(conversation: conversation),
    );
  }
}

class ChatPanelView extends StatefulWidget {
  final Conversation conversation;

  const ChatPanelView({super.key, required this.conversation});

  @override
  State<ChatPanelView> createState() => _ChatPanelViewState();
}

// 聊天面板核心组件，继承无状态组件StatelessWidget
// 负责展示聊天头部、消息列表、消息输入区域三大模块
class _ChatPanelViewState extends State<ChatPanelView> {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _apiService = ApiService();

  get _messages => null;

  @override
  void initState() {
    super.initState();
  }

  // 封装一个发送方法
  void _onSendPressed() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 调用 Bloc 发送事件
    context.read<ChatBloc>().add(ChatTextMessageSent(text));
    _textController.clear();
  }

  // 封装图片选择
  void _onImagePressed() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      context.read<ChatBloc>().add(ChatImageSent(pickedFile));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    try {
      // A. 选择图片
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      // B. 上传图片到 MinIO
      // 注意：我们在之前的 ApiService 中已经实现了 uploadFileAndGetObjectKey
      // 它会自动获取预签名 URL 并上传文件
      final String objectKey =
          await _apiService.uploadFileAndGetObjectKey(pickedFile);

      // C. 发送消息 (类型为 1)
      await _sendImageMessage(objectKey);
    } catch (e) {
      print("图片发送失败: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("图片发送失败: $e")));
      }
    }
  }

  Future<void> _sendImageMessage(String objectKey) async {
    // 乐观更新 UI
    final myMessage = ChatMessage(
      isMe: true,
      text: objectKey, // 图片消息的内容是 ObjectKey
      avatar: 'assets/image/2.jpg',
      sender: '我',
      contentType: 1, // <--- 标记为图片
    );

    setState(() {
      _messages.insert(0, myMessage);
      widget.conversation.lastMessage = "[图片]"; // 更新列表预览
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听错误状态，弹出提示
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
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
            // 1. 头部保持不变，除了人数可能需要从 Bloc 获取（暂时写死）
            _buildHeader(),

            // 2. 消息列表 (使用 BlocBuilder)
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.status == ChatStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    reverse: true, // 聊天列表反向，最新在底部
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return message.isMe
                          ? _buildMyMessage(context, message)
                          : _buildOthersMessage(context, message);
                    },
                  );
                },
              ),
            ),

            // 3. 输入框区域
            _buildInputArea(context),
          ],
        ),
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
          // 使用 widget.conversation 获取数据
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

  Widget _buildInputArea(BuildContext context) {
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
                _buildInputToolIcon(
                    Icons.image_outlined, _onImagePressed), // 绑定图片点击事件
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
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (previous, current) =>
                    previous.isSending != current.isSending,
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isSending ? null : _onSendPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6584FE),
                    ),
                    child: state.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('发送'),
                  );
                },
              ),
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
          CircleAvatar(
            // 增加空值检查
            backgroundImage: AssetImage(message.avatar.isNotEmpty
                    ? message.avatar
                    : 'assets/image/42.png' // 确保你有这个默认图片
                ),
            // 或者干脆如果不显示图片，就显示一个背景色
            backgroundColor: message.avatar.isEmpty ? Colors.grey : null,
            child: message.avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  // 私有方法：构建消息输入区的工具图标按钮（统一样式）
  // 参数：icon - 图标数据（如Icons.emoji_emotions_outlined）
  Widget _buildInputToolIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: _pickAndSendImage, // 图标点击事件（暂为空实现）
      icon: Icon(
        icon,
        color: Colors.white70, // 图标颜色：半透明白色
        size: 22, // 图标大小22
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    if (message.contentType == 1) {
      // --- 图片消息 ---
      // 获取完整的图片 URL
      final fullUrl = _apiService.getFullAvatarUrl(message.text);

      return GestureDetector(
        onTap: () {
          // TODO: 点击查看大图
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // --- 文本消息 (原有的逻辑) ---
      return Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      );
    }
  }
}
