import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/providers/services_provider.dart';

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  // 1. 初始化：加载历史 + 监听实时消息
  @override
  Future<List<ChatMessage>> build(String conversationId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    // 监听 MQTT
    final sub = ref.listen(mqttStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.senderId == conversationId ||
            event.senderId == currentUser.userId) {
          _addMessage(ChatMessage(
            isMe: event.senderId == currentUser.userId,
            sender: event.senderId,
            text: event.text,
            avatar: '',
            contentType: 0,
          ));
        }
      });
    });

    // 这里的 ref.onDispose 不需要手动调，listen 会自动销毁

    final api = ref.read(apiServiceProvider);
    return await api.getMessageHistory(conversationId,
        currentUserId: currentUser.userId);
  }

  // 2. 发送文本
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = ref.read(currentUserProvider)!;
    final conversationId = this.conversationId; // 获取 Family 参数

    final tempMsg = ChatMessage(
      isMe: true,
      text: text,
      sender: currentUser.userId,
      avatar: 'assets/image/34.jpg',
      contentType: 0,
    );
    _addMessage(tempMsg);

    try {
      await ref
          .read(apiServiceProvider)
          .sendMessage(conversationId, text, recipientId: conversationId);
    } catch (e) {
      print("发送失败: $e");
      // 实际项目中这里应该更新消息状态为失败
    }
  }

  // 3. 发送图片
  Future<void> sendImage(XFile image) async {
    final currentUser = ref.read(currentUserProvider)!;
    final api = ref.read(apiServiceProvider);
    final conversationId = this.conversationId;

    try {
      final objectKey = await api.uploadFileAndGetObjectKey(image);
      final tempMsg = ChatMessage(
        isMe: true,
        text: objectKey,
        sender: currentUser.userId,
        avatar: 'assets/image/34.jpg',
        contentType: 1,
      );
      _addMessage(tempMsg);
      await api.sendMessage(conversationId, objectKey,
          contentType: 1, recipientId: conversationId);
    } catch (e) {
      print("图片发送失败: $e");
    }
  }

  void _addMessage(ChatMessage msg) {
    final currentList = state.value ?? [];
    state = AsyncData([msg, ...currentList]);
  }
}
