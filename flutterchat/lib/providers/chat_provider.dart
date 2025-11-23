import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:riverpod/riverpod.dart';

part 'chat_provider.g.dart';

// 定义一个 Family Notifier，因为每个 conversationId 都有自己独立的状态
@riverpod
class Chat extends _$Chat {
  late String _conversationId;

  // 1. build 方法替代了 "ChatStarted" 事件
  // Riverpod 会自动处理：Loading -> Data(List) -> Error
  @override
  Future<List<ChatMessage>> build(String conversationId) async {
    _conversationId = conversationId;

    // 获取当前用户 ID
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    // 监听 MQTT 消息流
    // 这里的逻辑非常强大：只要有新消息，直接更新状态
    final sub = ref.listen(mqttMessageStreamProvider, (previous, next) {
      next.whenData((event) {
        // 过滤：只处理当前会话的消息
        if (event.senderId == _conversationId ||
            event.senderId == currentUser.userId) {
          _addMessage(ChatMessage(
            isMe: event.senderId == currentUser.userId,
            sender: event.senderId,
            text: event.text,
            avatar: '', // 暂空
            contentType: 0,
          ));
        }
      });
    });

    // 加载历史记录
    final api = ref.read(apiServiceProvider);
    return await api.getMessageHistory(conversationId,
        currentUserId: currentUser.userId);
  }

  // 2. 发送文本 (替代 ChatTextMessageSent)
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = ref.read(currentUserProvider)!;

    // A. 乐观更新
    final tempMsg = ChatMessage(
      isMe: true,
      text: text,
      sender: currentUser.userId,
      avatar: 'assets/image/34.jpg',
      contentType: 0,
    );
    _addMessage(tempMsg);

    // B. 调用 API
    try {
      final api = ref.read(apiServiceProvider);
      await api.sendMessage(_conversationId, text,
          contentType: 0, recipientId: _conversationId);
    } catch (e) {
      // 发送失败处理，这里可以把刚才那条消息标记为失败，或者弹个 Toast
      print("发送失败: $e");
    }
  }

  // 3. 发送图片 (替代 ChatImageSent)
  Future<void> sendImage(XFile image) async {
    final currentUser = ref.read(currentUserProvider)!;
    final api = ref.read(apiServiceProvider);

    try {
      // 先上传
      final objectKey = await api.uploadFileAndGetObjectKey(image);

      // 再乐观更新
      final tempMsg = ChatMessage(
        isMe: true,
        text: objectKey,
        sender: currentUser.userId,
        contentType: 1,
        avatar: '',
      );
      _addMessage(tempMsg);

      // 最后发送
      await api.sendMessage(_conversationId, objectKey,
          contentType: 1, recipientId: _conversationId);
    } catch (e) {
      print("图片发送失败: $e");
    }
  }

  // 辅助方法：手动往列表头插一条数据
  void _addMessage(ChatMessage msg) {
    final currentList = state.value ?? [];
    // 触发状态更新，UI 自动重绘
    state = AsyncData([msg, ...currentList]);
  }
}
