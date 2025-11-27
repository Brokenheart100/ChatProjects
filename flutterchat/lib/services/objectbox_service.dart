import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutterchat/objectbox.g.dart'; // 必须引用生成的绑定文件
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/services/logger_service.dart';

class ObjectBoxService {
  /// ObjectBox Store 实例
  late final Store store;

  /// 消息表盒子
  late final Box<ChatMessage> messageBox;

  /// 会话表盒子
  late final Box<Conversation> conversationBox;

  // 私有构造函数，确保只能通过 init 初始化
  ObjectBoxService._create(this.store) {
    messageBox = store.box<ChatMessage>();
    conversationBox = store.box<Conversation>();
  }

  /// 初始化数据库
  /// 在 main.dart 中调用
  static Future<ObjectBoxService> init() async {
    // final docsDir = await getApplicationDocumentsDirectory();
    // 数据库文件将存储在 app_documents/chat-db/ 目录下
    // final dbPath = p.join(docsDir.path, "chat-db");
    final dbPath = p.join(Directory.current.path, "chat-db-dev");
    // 如果是第一次运行，openStore 会自动创建文件
    final store = await openStore(directory: dbPath);

    logger.i("📦 [ObjectBox] 数据库已初始化: $dbPath");
    return ObjectBoxService._create(store);
  }

  // ==========================================
  //                 消息相关操作
  // ==========================================

  /// 保存或更新单条消息
  /// 核心逻辑：根据 uuid 查找本地是否已存在，如果存在则复用 id 以执行更新
  void saveMessage(ChatMessage msg) {
    if (msg.id == 0) {
      // 正确写法：先 build 再 close
      final query =
          messageBox.query(ChatMessage_.uuid.equals(msg.uuid)).build();
      final existing = query.findFirst();
      query.close(); // 这里的 query 是 Query 对象，所以有 close 方法

      if (existing != null) {
        msg.id = existing.id;
      }
    }
    messageBox.put(msg);
  }

  /// 批量保存消息 (通常用于 API 拉取历史记录后)
  void saveMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;

    // 开启事务以提高批量写入性能
    store.runInTransaction(TxMode.write, () {
      for (var msg in messages) {
        // 必须逐个检查 ID，防止 uuid 冲突导致的数据覆盖错误
        if (msg.id == 0) {
          final query =
              messageBox.query(ChatMessage_.uuid.equals(msg.uuid)).build();
          final existing = query.findFirst();
          query.close();
          if (existing != null) {
            msg.id = existing.id;
          }
        }
        messageBox.put(msg);
      }
    });
  }

  /// 监听某会话的消息流 (UI 实时更新的核心)
  /// 返回：Stream<List<ChatMessage>>
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    // 构建查询：按会话 ID 过滤，按发送时间倒序
    final queryBuilder = messageBox
        .query(ChatMessage_.conversationId.equals(conversationId))
      ..order(ChatMessage_.sentAt, flags: Order.descending);

    // triggerImmediately: true 确保监听的一瞬间 UI 就能拿到当前数据，不留白
    return queryBuilder.watch(triggerImmediately: true).map((query) {
      final messages = query.find();
      // 可以在这里做一些额外的内存处理，比如解密等
      return messages;
    });
  }

  /// 获取最后一条消息 (用于调试或更新会话列表)
  ChatMessage? getLastMessage(String conversationId) {
    // 1. 创建构建器 (QueryBuilder)
    final builder = messageBox
        .query(ChatMessage_.conversationId.equals(conversationId))
      ..order(ChatMessage_.sentAt, flags: Order.descending);

    // 2. 生成查询对象 (Query)
    final query = builder.build();

    // 3. 执行查找
    final msg = query.findFirst();

    // 4. 关闭查询对象释放资源
    query.close();

    return msg;
  }

  // ==========================================
  //                 会话相关操作
  // ==========================================

  /// 保存或更新会话
  void saveConversation(Conversation conversation) {
    if (conversation.id == 0) {
      final query = conversationBox
          .query(Conversation_.uuid.equals(conversation.uuid))
          .build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) {
        conversation.id = existing.id;
      }
    }
    conversationBox.put(conversation);
  }

  /// 批量保存会话
  void saveConversations(List<Conversation> conversations) {
    store.runInTransaction(TxMode.write, () {
      for (var c in conversations) {
        if (c.id == 0) {
          final query =
              conversationBox.query(Conversation_.uuid.equals(c.uuid)).build();
          final existing = query.findFirst();
          query.close();
          if (existing != null) c.id = existing.id;
        }
        conversationBox.put(c);
      }
    });
  }

  /// 获取所有会话 (按最后消息时间倒序)
  List<Conversation> getAllConversations() {
    final query = conversationBox.query()
      ..order(Conversation_.lastMessageAt, flags: Order.descending);
    return query.build().find();
  }

  /// 监听会话列表变化 (如果你想把会话列表也做成离线优先)
  Stream<List<Conversation>> watchConversations() {
    final queryBuilder = conversationBox.query()
      ..order(Conversation_.lastMessageAt, flags: Order.descending);

    return queryBuilder.watch(triggerImmediately: true).map((q) => q.find());
  }

  // ==========================================
  //                 通用操作
  // ==========================================

  /// 清空所有数据 (用于注销登录时)
  void clearAll() {
    store.runInTransaction(TxMode.write, () {
      messageBox.removeAll();
      conversationBox.removeAll();
    });
    logger.w("📦 [ObjectBox] 所有本地数据已清空");
  }

  /// 关闭数据库 (App 退出时调用)
  void close() {
    store.close();
  }
}
