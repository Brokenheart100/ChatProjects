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

    ref.listen(mqttSystemStreamProvider, (prev, next) {
      next.whenData((event) {
        if (event.type == 'SYSTEM_GROUP_CREATED') {
          _handleGroupCreated(event.data);
        }
      });
    });

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
      final db = ref.read(objectBoxProvider); // 1. 获取 DB 实例

      logger.i("📥 [ConversationList] 正在从 API 拉取会话列表...");
      final list =
          await api.getConversations(currentUserId: currentUser.userId);
      // 2. ⚠️ 必须有这一步：把拉取到的最新数据写入本地
      // 这样下次启动，或者 UI 监听流的时候，才能看到新名字
      db.saveConversations(list);

      logger.i("✅ [ConversationList] 列表加载成功并已同步到本地");
      return list;
    } catch (e, stack) {
      logger.e("❌ 加载失败", error: e, stackTrace: stack);
      rethrow;
    }
  }

  void _handleGroupCreated(Map<String, dynamic> data) {
    final groupId = data['groupId']?.toString() ?? '';
    final groupName = data['name'] ?? '未命名群聊';

    logger.i("✨ [System] 被拉入新群: $groupName ($groupId)");

    // 1. 构造 Conversation 对象
    final newGroup = Conversation(
      id: 0, // 本地 ID
      uuid: groupId, // 真实 UUID
      recipientId: '', // 群聊无
      name: groupName,
      avatar: '', // 默认头像
      lastMessage: '你已加入群聊',
      lastMessageAt: DateTime.now(), // 确保置顶
      isGroup: true, // ✅ 标记为群聊
    );

    // 2. 存入 ObjectBox
    final db = ref.read(objectBoxProvider);
    db.saveConversation(newGroup);

    // 3. 更新 UI 列表 (插入头部)
    final currentList = List<Conversation>.from(state.value ?? []);

    // 防止重复添加
    if (!currentList.any((c) => c.uuid == groupId)) {
      currentList.insert(0, newGroup);
      state = AsyncData(currentList);
    }
  }

  void createOrSelect(Contact contact) {
    logger.i(
        "👉 [createOrSelect] 点击: ${contact.name} (isGroup: ${contact.isGroup})");

    final currentList = List<Conversation>.from(state.value ?? []);

    // 1. 尝试匹配 (逻辑不变)
    int index = -1;
    // 群聊匹配 UUID
    if (contact.isGroup) {
      index = currentList.indexWhere((c) => c.uuid == contact.id);
    } else {
      // 私聊匹配 RecipientId
      index = currentList
          .indexWhere((c) => !c.isGroup && c.recipientId == contact.id);
    }

    if (index != -1) {
      logger.i("📂 找到列表中的会话，直接选中");
      ref.read(selectedConversationIndexProvider.notifier).set(index);
    } else {
      // 2. 没找到 (可能是被移除了，或者是新私聊)
      logger.i("🆕 列表中未找到，准备恢复或创建...");

      // ✅ 核心修复：
      // 如果是群聊 (isGroup=true)：必须复用 contact.id 作为会话 UUID (找回历史记录的关键!)
      // 如果是私聊 (isGroup=false)：生成新的随机 UUID
      final useContactIdAsUuid = contact.isGroup;

      final newUuid = useContactIdAsUuid ? contact.id : const Uuid().v4();

      final newConv = Conversation(
        id: 0,
        uuid: newUuid, // 群聊复用旧ID，私聊用新ID
        recipientId: contact.isGroup ? '' : contact.id, // 群聊无接收人
        name: contact.name,
        avatar: contact.avatarUrl ?? '',
        lastMessage: '', // 暂时为空，进去后 ObjectBox 会加载历史
        lastMessageAt: DateTime.now(),
        isGroup: contact.isGroup,
      );

      // 3. 存入 DB 并更新 UI
      final db = ref.read(objectBoxProvider);
      db.saveConversation(newConv);

      currentList.insert(0, newConv);
      state = AsyncData(currentList);
      ref.read(selectedConversationIndexProvider.notifier).set(0);

      logger.i("✨ 会话已恢复/创建: ${newConv.name} (UUID: $newUuid)");
    }
  }

  void delete(String uuid) {
    final currentList = List<Conversation>.from(state.value ?? []);
    // ✅ 修复：比对 uuid (String)
    currentList.removeWhere((c) => c.uuid == uuid);
    state = AsyncData(currentList);
    ref.read(selectedConversationIndexProvider.notifier).set(0);
    ref.read(objectBoxProvider);
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
    final index = currentList.indexWhere(
        (c) => c.uuid.trim().toLowerCase() == convId.trim().toLowerCase());

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

    // 1. 查重 (防止重复添加)
    final index = currentList.indexWhere((c) =>
        c.uuid.trim().toLowerCase() == newConv.uuid.trim().toLowerCase());
    if (index != -1) {
      // 已存在，直接选中
      ref.read(selectedConversationIndexProvider.notifier).set(index);
      return;
    }

    // 2. 插入头部
    currentList.insert(0, newConv);

    // 3. 更新状态
    state = AsyncData(currentList);

    // 4. ✅ 关键：必须选中第 0 项，这样切换回 ChatView 时，显示的就是新群聊
    ref.read(selectedConversationIndexProvider.notifier).set(0);
  }
}
