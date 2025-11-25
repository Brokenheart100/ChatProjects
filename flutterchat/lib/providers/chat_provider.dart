import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/providers/services_provider.dart'; // ✅ 必须引入这个！
import 'package:flutterchat/services/logger_service.dart'; // ✅ 引入 Logger

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  // 1. 修改 build 方法，增加 recipientId
  @override
  Future<List<ChatMessage>> build(
      String conversationId, String recipientId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    final api = ref.read(apiServiceProvider);
    // ✅ 修复：移除 unused 'sub' 变量，直接调用 ref.listen
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      // ✅ 修复：使用 whenData 处理 AsyncValue
      next.whenData((event) {
        // 过滤逻辑
        if (event.conversationId == conversationId) {
          _addMessage(ChatMessage(
            isMe: event.senderId == currentUser.userId,
            sender: event.senderId,
            text: event.text,
            avatar: (event.senderId == currentUser.userId)
                ? api.getFullAvatarUrl(currentUser.avatarUrl)
                : '',
            contentType: 0,
          ));
        }
      });
    });

    // final api = ref.read(apiServiceProvider);
    // 1. 从 API 获取原始历史记录 (此时头像为空)
    final rawHistory = await api.getMessageHistory(conversationId,
        currentUserId: currentUser.userId);

    // 2. 🔍 核心修复：后期加工，注入头像
    final processedHistory = rawHistory.map((msg) {
      if (msg.isMe) {
        // 如果是“我”发的消息，注入当前用户的真实头像
        return msg.copyWith(
            avatar: api.getFullAvatarUrl(currentUser.avatarUrl));
      }
      // 如果是对方发的，暂时保持空，或者我们可以在 UI 层用会话头像兜底
      return msg;
    }).toList();
    // 调用 API 获取历史记录 (只需要 conversationId)
    return processedHistory;
  }

  // 2. 发送文本
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = ref.read(currentUserProvider)!;

    final api = ref.read(apiServiceProvider);
    // 获取参数 (Riverpod 生成的属性)
    final currentConvId = conversationId;
    final currentRecipId = recipientId;

    logger.i(
        "👤 当前发送者: ${currentUser.username}, 头像Key: ${currentUser.avatarUrl}");
    // A. 乐观更新
    final tempMsg = ChatMessage(
      isMe: true,
      text: text,
      sender: currentUser.userId,
      avatar: api.getFullAvatarUrl(currentUser.avatarUrl),
      contentType: 0,
    );
    _addMessage(tempMsg);

    // B. 调用 API
    try {
      final api = ref.read(apiServiceProvider);
      await api.sendMessage(currentConvId, text,
          contentType: 0, recipientId: currentRecipId);
    } catch (e) {
      // ✅ 修复：使用 logger 代替 print
      logger.e("发送失败", error: e);
    }
  }

  // 3. 发送图片
  Future<void> sendImage(XFile image) async {
    final currentUser = ref.read(currentUserProvider)!;
    final api = ref.read(apiServiceProvider);

    // 获取参数
    final currentConvId = conversationId;
    final currentRecipId = recipientId;

    try {
      final objectKey = await api.uploadFileAndGetObjectKey(image);

      final tempMsg = ChatMessage(
        isMe: true,
        text: objectKey,
        sender: currentUser.userId,
        avatar: api.getFullAvatarUrl(currentUser.avatarUrl),
        contentType: 1,
      );
      _addMessage(tempMsg);

      await api.sendMessage(currentConvId, objectKey,
          contentType: 1, recipientId: currentRecipId);
    } catch (e) {
      // ✅ 修复：使用 logger 代替 print
      logger.e("图片发送失败", error: e);
    }
  }

  void _addMessage(ChatMessage msg) {
    final currentList = state.value ?? [];
    state = AsyncData([msg, ...currentList]);
  }
}
