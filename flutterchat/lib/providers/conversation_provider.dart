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
      return [];
    }

    // 监听 MQTT
    ref.listen(mqttMessageStreamProvider, (prev, next) {
      next.whenData((event) {
        _updateOrAdd(event.conversationId, event.text, event.senderId,
            currentUser.userId);
      });
    });

    // 加载初始列表
    try {
      final api = ref.read(apiServiceProvider);
      // 假设 api.getConversations 已经适配好了 ObjectBox Model 的构造
      // 如果没有，你需要去 api_service.dart 里也改一下
      final list =
          await api.getConversations(currentUserId: currentUser.userId);
      return list;
    } catch (e, stack) {
      logger.e("❌ 加载失败", error: e, stackTrace: stack);
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
      // ✅ 修复：适配 ObjectBox 构造函数
      final newConv = Conversation(
        id: 0, // 本地 ID
        uuid: const Uuid().v4(), // 业务 UUID
        recipientId: contact.id,
        name: contact.name,
        avatar: contact.avatarUrl ?? '',
        lastMessage: '',
        lastMessageAt: DateTime.now(), // 使用 DateTime
        isGroup: false,
      );
      state = AsyncData([newConv, ...currentList]);
      ref.read(selectedConversationIndexProvider.notifier).set(0);
    }
  }

  void delete(String uuid) {
    final currentList = List<Conversation>.from(state.value ?? []);
    // ✅ 修复：比对 uuid (String)
    currentList.removeWhere((c) => c.uuid == uuid);
    state = AsyncData(currentList);
    ref.read(selectedConversationIndexProvider.notifier).set(0);
  }

  // 收到消息更新列表
  void _updateOrAdd(
      String convId, String text, String senderId, String myUserId) {
    final currentList = List<Conversation>.from(state.value ?? []);

    final currentIndex = ref.read(selectedConversationIndexProvider);
    String? selectedConversationUuid;
    if (currentIndex >= 0 && currentIndex < currentList.length) {
      selectedConversationUuid = currentList[currentIndex].uuid; // 记录 UUID
    }

    // ✅ 修复：比对 uuid (String)
    final index = currentList.indexWhere((c) => c.uuid == convId);

    if (index != -1) {
      final old = currentList[index];
      currentList.removeAt(index);

      // ✅ 修复：构造新对象
      final newConv = Conversation(
        id: old.id, // 保持本地 ID 不变
        uuid: old.uuid,
        recipientId: old.recipientId,
        name: old.name,
        avatar: old.avatar,
        lastMessage: text,
        lastMessageAt: DateTime.now(),
        isGroup: old.isGroup,
      );

      currentList.insert(0, newConv);
      state = AsyncData(currentList);
    } else {
      ref.invalidateSelf();
      return;
    }

    // 修正选中索引
    if (selectedConversationUuid != null) {
      final newIndex =
          currentList.indexWhere((c) => c.uuid == selectedConversationUuid);
      if (newIndex != -1 && newIndex != currentIndex) {
        ref.read(selectedConversationIndexProvider.notifier).set(newIndex);
      }
    }
  }

  // 手动添加一个会话到列表顶部 (用于新建群聊的瞬间反馈)
  void addManualItem(Conversation newConv) {
    final currentList = List<Conversation>.from(state.value ?? []);

    // 避免重复添加
    if (currentList.any((c) => c.uuid == newConv.uuid)) return;

    currentList.insert(0, newConv);
    state = AsyncData(currentList);

    // 选中第一个 (即刚添加的这个)
    ref.read(selectedConversationIndexProvider.notifier).set(0);
  }
}
