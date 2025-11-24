import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:uuid/uuid.dart';

part 'conversation_provider.g.dart';

// 选中项索引
@riverpod
class SelectedConversationIndex extends _$SelectedConversationIndex {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

// 会话列表
@Riverpod(keepAlive: true)
class ConversationList extends _$ConversationList {
  @override
  Future<List<Conversation>> build() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    // 监听 MQTT 更新列表
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      next.whenData((event) {
        _updateOrAdd(event.conversationId, event.text);
      });
    });

    return await ref
        .read(apiServiceProvider)
        .getConversations(currentUserId: currentUser.userId);
  }

  // 创建或选中
  void createOrSelect(Contact contact) {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((c) => c.recipientId == contact.id);

    if (index != -1) {
      ref.read(selectedConversationIndexProvider.notifier).set(index);
    } else {
      final newConv = Conversation(
        id: const Uuid().v4(),
        recipientId: contact.id,
        name: contact.name,
        avatar: contact.avatarUrl ?? '',
        lastMessage: '',
        time: _formatTime(DateTime.now()),
        messages: [],
      );
      state = AsyncData([newConv, ...currentList]);
      ref.read(selectedConversationIndexProvider.notifier).set(0);
    }
  }

  void _updateOrAdd(String convId, String text) {
    final currentList = List<Conversation>.from(state.value ?? []);
    final index = currentList.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final old = currentList[index];
      currentList.removeAt(index);
      currentList.insert(
          0,
          Conversation(
            id: old.id,
            recipientId: old.recipientId,
            name: old.name,
            avatar: old.avatar,
            lastMessage: text,
            time: _formatTime(DateTime.now()),
            messages: old.messages,
          ));
      state = AsyncData(currentList);
    } else {
      ref.invalidateSelf(); // 重新拉取
    }
  }

  void delete(String conversationId) {
    final currentList = List<Conversation>.from(state.value ?? []);

    // 1. 从列表中移除
    currentList.removeWhere((c) => c.id == conversationId);

    // 2. 更新状态
    state = AsyncData(currentList);

    // 3. (可选) 处理选中项逻辑
    // 如果删除的是当前选中的会话，需要重置选中索引或者清空右侧
    // 这里简单处理：如果列表空了或者删除了当前项，重置索引
    // 实际项目中可能需要通知 UI 清空右侧面板
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
