import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  @override
  Stream<List<ChatMessage>> build(String conversationId, String recipientId) {
    final db = ref.watch(objectBoxProvider);
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) return const Stream.empty();

    _syncHistory(conversationId, currentUser.userId);
    _listenMqtt(conversationId, currentUser.userId);

    return db.watchMessages(conversationId);
  }

  Future<void> _syncHistory(String conversationId, String currentUserId) async {
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(objectBoxProvider);

      final history = await api.getMessageHistory(conversationId,
          currentUserId: currentUserId);

      final processed = history.map((m) {
        if (m.isMe) {
          return m.copyWith(
              avatar: api
                  .getFullAvatarUrl(ref.read(currentUserProvider)!.avatarUrl));
        }
        return m;
      }).toList();

      db.saveMessages(processed);
    } catch (e) {
      logger.w("同步历史失败: $e");
    }
  }

  void _listenMqtt(String conversationId, String currentUserId) {
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.conversationId == conversationId) {
          final db = ref.read(objectBoxProvider);
          final api = ref.read(apiServiceProvider);
          final currentUser = ref.read(currentUserProvider)!;

          final msg = ChatMessage(
            id: 0,
            uuid: const Uuid().v4(),
            conversationId: conversationId,
            senderId: event.senderId,
            text: event.text,
            isMe: event.senderId == currentUserId,
            avatar: (event.senderId == currentUserId)
                ? api.getFullAvatarUrl(currentUser.avatarUrl)
                : '',
            sentAt: event.timestamp,
            status: 1,
          );
          db.saveMessage(msg);
        }
      });
    });
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    final currentUser = ref.read(currentUserProvider)!;
    final db = ref.read(objectBoxProvider);
    final api = ref.read(apiServiceProvider);

    final tempUuid = const Uuid().v4();

    final tempMsg = ChatMessage(
      id: 0,
      uuid: tempUuid,
      conversationId: conversationId,
      senderId: currentUser.userId,
      text: text,
      isMe: true,
      avatar: api.getFullAvatarUrl(currentUser.avatarUrl),
      sentAt: DateTime.now(),
      status: 0,
    );

    db.saveMessage(tempMsg);

    try {
      await api.sendMessage(conversationId, text,
          contentType: 0, recipientId: recipientId);

      // ✅ 修复：移除 await
      db.saveMessage(tempMsg.copyWith(status: 1));
    } catch (e) {
      logger.e("发送失败", error: e);
      db.saveMessage(tempMsg.copyWith(status: 2));
    }
  }

  Future<void> sendImage(XFile image) async {
    final currentUser = ref.read(currentUserProvider)!;
    final db = ref.read(objectBoxProvider);
    final api = ref.read(apiServiceProvider);

    String objectKey;
    try {
      objectKey = await api.uploadFileAndGetObjectKey(image);
    } catch (e) {
      logger.e("图片上传失败", error: e);
      return;
    }

    final tempUuid = const Uuid().v4();

    final tempMsg = ChatMessage(
      id: 0,
      uuid: tempUuid,
      conversationId: conversationId,
      senderId: currentUser.userId,
      text: objectKey,
      isMe: true,
      avatar: api.getFullAvatarUrl(currentUser.avatarUrl),
      contentType: 1,
      sentAt: DateTime.now(),
      status: 0,
    );

    // ✅ 修复：移除 await
    db.saveMessage(tempMsg);

    try {
      await api.sendMessage(conversationId, objectKey,
          contentType: 1, recipientId: recipientId);

      // ✅ 修复：移除 await
      db.saveMessage(tempMsg.copyWith(status: 1));
    } catch (e) {
      logger.e("图片发送业务失败", error: e);
      // ✅ 修复：移除 await
      db.saveMessage(tempMsg.copyWith(status: 2));
    }
  }
}
