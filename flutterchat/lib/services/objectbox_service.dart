import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutterchat/objectbox.g.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/user_entity.dart';
import 'package:flutterchat/services/logger_service.dart'; // 引入 Logger

class ObjectBoxService {
  late final Store store;
  late final Box<ChatMessage> messageBox;
  late final Box<Conversation> conversationBox;
  late final Box<UserEntity> userBox;

  Admin? _admin;

  ObjectBoxService._create(this.store) {
    messageBox = store.box<ChatMessage>();
    conversationBox = store.box<Conversation>();
    userBox = store.box<UserEntity>();

    if (Admin.isAvailable()) {
      _admin = Admin(store);
      logger.i("🔧 [ObjectBox] Admin 调试接口已启动 (http://127.0.0.1:8090)");
    }
  }

  static Future<ObjectBoxService> init() async {
    String dbDirectoryPath;
    bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (kDebugMode && isDesktop) {
      dbDirectoryPath = p.join(Directory.current.path, "chat-db-dev");
      logger.d("📂 [ObjectBox] 开发模式路径: $dbDirectoryPath");
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbDirectoryPath = p.join(docsDir.path, "chat-db");
      logger.d("📱 [ObjectBox] 生产模式路径: $dbDirectoryPath");
    }

    final store = await openStore(directory: dbDirectoryPath);
    logger.i("📦 [ObjectBox] 数据库初始化成功");
    return ObjectBoxService._create(store);
  }

  // ================== 消息操作 ==================

  void saveMessage(ChatMessage msg) {
    bool isUpdate = false;
    // 查重逻辑
    if (msg.id == 0) {
      final query =
          messageBox.query(ChatMessage_.uuid.equals(msg.uuid)).build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) {
        msg.id = existing.id; // 复用 ID
        isUpdate = true;
      }
    }

    messageBox.put(msg);

    if (isUpdate) {
      logger.d(
          "🔄 [Msg] 更新消息: ${msg.text} (UUID: ${msg.uuid}, LocalID: ${msg.id})");
    } else {
      logger.d(
          "💾 [Msg] 插入新消息: ${msg.text} (UUID: ${msg.uuid}, LocalID: ${msg.id})");
    }
  }

  void saveMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    logger.i("📚 [Msg] 准备批量保存 ${messages.length} 条消息...");

    store.runInTransaction(TxMode.write, () {
      for (var msg in messages) {
        if (msg.id == 0) {
          final query =
              messageBox.query(ChatMessage_.uuid.equals(msg.uuid)).build();
          final existing = query.findFirst();
          query.close();
          if (existing != null) msg.id = existing.id;
        }
        messageBox.put(msg);
      }
    });
    logger.i("✅ [Msg] 批量保存完成");
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    logger.i("👀 [Msg] 开始监听会话消息流: $conversationId");
    final queryBuilder = messageBox
        .query(ChatMessage_.conversationId.equals(conversationId))
      ..order(ChatMessage_.sentAt, flags: Order.descending);

    return queryBuilder.watch(triggerImmediately: true).map((q) {
      final list = q.find();
      logger.i("🌊 [Msg] 消息流更新，当前共 ${list.length} 条");
      return list;
    });
  }

  // ================== 会话操作 ==================

  void saveConversation(Conversation conversation) {
    bool isUpdate = false;
    if (conversation.id == 0) {
      final query = conversationBox
          .query(Conversation_.uuid.equals(conversation.uuid))
          .build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) {
        conversation.id = existing.id;
        isUpdate = true;
      }
    }
    conversationBox.put(conversation);

    if (isUpdate) {
      logger.d(
          "🔄 [Conv] 更新会话: ${conversation.name} (UUID: ${conversation.uuid})");
    } else {
      logger.d(
          "💾 [Conv] 新建会话: ${conversation.name} (UUID: ${conversation.uuid})");
    }
  }

  void saveConversations(List<Conversation> conversations) {
    if (conversations.isEmpty) return;
    logger.i("📚 [Conv] 准备批量保存 ${conversations.length} 个会话...");

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
    logger.i("✅ [Conv] 批量保存完成");
  }

  Stream<List<Conversation>> watchConversations() {
    final queryBuilder = conversationBox.query()
      ..order(Conversation_.lastMessageAt, flags: Order.descending);
    return queryBuilder.watch(triggerImmediately: true).map((q) => q.find());
  }

  // ================== 用户缓存操作 ==================

  // 1. 获取用户
  UserEntity? getUser(String userId) {
    final query = userBox.query(UserEntity_.userId.equals(userId)).build();
    final user = query.findFirst();
    query.close();

    if (user != null) {
      logger.d("⚡ [User] 命中本地缓存: ${user.username} ($userId)");
    } else {
      logger.d("🤷‍♂️ [User] 本地未找到用户: $userId");
    }
    return user;
  }

  // 2. 保存单个用户
  void saveUser(UserEntity user) {
    bool isUpdate = false;
    if (user.id == 0) {
      // 这里不需要重新 query，因为 getUser 内部是独立的查询
      // 但为了获取 ID 进行 update，我们需要在内部查一下 ID
      final q = userBox.query(UserEntity_.userId.equals(user.userId)).build();
      final existing = q.findFirst();
      q.close();

      if (existing != null) {
        user.id = existing.id;
        isUpdate = true;
      }
    }
    userBox.put(user);

    if (isUpdate) {
      logger.d("🔄 [User] 更新用户资料: ${user.username}");
    } else {
      logger.d("💾 [User] 缓存新用户: ${user.username}");
    }
  }

  // 3. 批量保存用户
  void saveUsers(List<UserEntity> users) {
    if (users.isEmpty) return;
    logger.i("📚 [User] 准备批量缓存 ${users.length} 个用户...");

    store.runInTransaction(TxMode.write, () {
      for (var u in users) {
        if (u.id == 0) {
          final q = userBox.query(UserEntity_.userId.equals(u.userId)).build();
          final existing = q.findFirst();
          q.close();
          if (existing != null) u.id = existing.id;
        }
        userBox.put(u);
      }
    });
    logger.i("✅ [User] 批量缓存完成");
  }

  // ================== 通用 ==================

  void close() {
    _admin?.close();
    store.close();
    logger.w("🛑 [ObjectBox] 数据库已关闭");
  }
}
