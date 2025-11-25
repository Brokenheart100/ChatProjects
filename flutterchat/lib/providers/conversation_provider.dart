import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:uuid/uuid.dart';

part 'conversation_provider.g.dart';

// 1. 选中项索引 Provider
@riverpod
class SelectedConversationIndex extends _$SelectedConversationIndex {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

// 2. 会话列表 Provider
@Riverpod(keepAlive: true)
class ConversationList extends _$ConversationList {
  @override
  Future<List<Conversation>> build() async {
    logger.i("🚀 [ConversationList] build() 开始初始化...");

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      logger.w("🚫 [ConversationList] 当前用户未登录，返回空列表");
      return [];
    }

    // 监听 MQTT
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      next.whenData((event) {
        logger.d(
            "📡 [ConversationList] 收到 MQTT: Sender=${event.senderId}, Text=${event.text}");

        _updateOrAdd(event.conversationId, event.text, event.senderId,
            currentUser.userId);
      });
    });

    // 加载初始列表
    try {
      final api = ref.read(apiServiceProvider);
      logger.i("📥 [ConversationList] 正在拉取列表...");
      final list =
          await api.getConversations(currentUserId: currentUser.userId);
      return list;
    } catch (e, stack) {
      logger.e("❌ [ConversationList] 加载失败", error: e, stackTrace: stack);
      rethrow;
    }
  }

  // 创建新会话
  void createOrSelect(Contact contact) {
    logger.i("👉 [createOrSelect] 点击联系人: ${contact.name}");

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

  // ✅ 补回丢失的方法：删除会话
  void delete(String conversationId) {
    final currentList = List<Conversation>.from(state.value ?? []);

    // 1. 从列表中移除
    currentList.removeWhere((c) => c.id == conversationId);

    // 2. 更新状态
    state = AsyncData(currentList);

    // 3. 如果删除了当前选中的项，或者导致索引越界，重置索引为 0
    // (简单处理，实际可以更复杂)
    ref.read(selectedConversationIndexProvider.notifier).set(0);

    logger.i("🗑️ [delete] 已从列表中移除会话: $conversationId");
  }

  // 收到消息更新列表 (带自动修正选中项逻辑)
  void _updateOrAdd(
      String convId, String text, String senderId, String myUserId) {
    final currentList = List<Conversation>.from(state.value ?? []);

    // 1. 记住当前选中的会话 ID
    final currentIndex = ref.read(selectedConversationIndexProvider);
    String? selectedConversationId;
    if (currentIndex >= 0 && currentIndex < currentList.length) {
      selectedConversationId = currentList[currentIndex].id;
    }

    // 2. 列表重排
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
            isGroup: old.isGroup,
          ));
      state = AsyncData(currentList);
    } else {
      // 新会话，刷新列表
      ref.invalidateSelf();
      return;
    }

    // 3. 修正选中索引
    if (selectedConversationId != null) {
      final newIndex =
          currentList.indexWhere((c) => c.id == selectedConversationId);
      if (newIndex != -1 && newIndex != currentIndex) {
        ref.read(selectedConversationIndexProvider.notifier).set(newIndex);
        logger.d("🧷 [AutoSelect] 选中索引修正: $currentIndex -> $newIndex");
      }
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
