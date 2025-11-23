import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod/riverpod.dart';
part 'conversation_provider.g.dart';

// 1. 选中项索引 Provider (简单的状态)
@riverpod
class SelectedConversationIndex extends _$SelectedConversationIndex {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

// 2. 会话列表 Provider
@riverpod
class ConversationList extends _$ConversationList {
  @override
  Future<List<Conversation>> build() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    // 监听 MQTT，实现列表置顶
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      next.whenData((event) {
        _updateOrAdd(event.conversationId, event.text, event.senderId,
            currentUser.userId);
      });
    });

    // 加载初始列表
    final api = ref.read(apiServiceProvider);
    return await api.getConversations(currentUserId: currentUser.userId);
  }

  // 创建新会话 (点击联系人)
  void createOrSelect(Contact contact) {
    final currentList = state.value ?? [];
    final index = currentList.indexWhere((c) => c.recipientId == contact.id);

    if (index != -1) {
      // 已存在，选中它
      ref.read(selectedConversationIndexProvider.notifier).set(index);
    } else {
      // 不存在，新建
      final newConv = Conversation(
        id: const Uuid().v4(),
        recipientId: contact.id,
        name: contact.name, // 应该优先用 remark
        avatar: contact.avatarUrl ?? '',
        lastMessage: '',
        time: _formatTime(DateTime.now()),
        messages: [],
      );

      // 更新状态
      state = AsyncData([newConv, ...currentList]);
      ref.read(selectedConversationIndexProvider.notifier).set(0);
    }
  }

  // 收到消息更新列表
  void _updateOrAdd(
      String convId, String text, String senderId, String myUserId) {
    final currentList = List<Conversation>.from(state.value ?? []);
    // 核心修复：使用 convId 匹配
    final index = currentList.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final old = currentList[index];
      // 更新并置顶
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

      // 如果置顶导致选中项变化，这里需要处理 selectedIndex，简单起见略过
    } else {
      // 这是一个新会话，重新拉取列表最安全
      ref.invalidateSelf(); // 让 Provider 重新执行 build()
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
