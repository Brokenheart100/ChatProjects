import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutterchat/objectbox.g.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/user_entity.dart'; // ✅ 必须引入这个

class ObjectBoxService {
  late final Store store;
  late final Box<ChatMessage> messageBox;
  late final Box<Conversation> conversationBox;
  late final Box<UserEntity> userBox; // ✅ 新增用户表盒子

  Admin? _admin;

  ObjectBoxService._create(this.store) {
    messageBox = store.box<ChatMessage>();
    conversationBox = store.box<Conversation>();
    userBox = store.box<UserEntity>(); // ✅ 初始化

    if (Admin.isAvailable()) {
      _admin = Admin(store);
    }
  }

  static Future<ObjectBoxService> init() async {
    String dbDirectoryPath;
    bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (kDebugMode && isDesktop) {
      dbDirectoryPath = p.join(Directory.current.path, "chat-db-dev");
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbDirectoryPath = p.join(docsDir.path, "chat-db");
    }

    final store = await openStore(directory: dbDirectoryPath);
    return ObjectBoxService._create(store);
  }

  // ================== 消息操作 ==================

  void saveMessage(ChatMessage msg) {
    if (msg.id == 0) {
      final query =
          messageBox.query(ChatMessage_.uuid.equals(msg.uuid)).build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) msg.id = existing.id;
    }
    messageBox.put(msg);
  }

  void saveMessages(List<ChatMessage> messages) {
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
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final queryBuilder = messageBox
        .query(ChatMessage_.conversationId.equals(conversationId))
      ..order(ChatMessage_.sentAt, flags: Order.descending);
    return queryBuilder.watch(triggerImmediately: true).map((q) => q.find());
  }

  // ================== 会话操作 ==================

  void saveConversation(Conversation conversation) {
    if (conversation.id == 0) {
      final query = conversationBox
          .query(Conversation_.uuid.equals(conversation.uuid))
          .build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) conversation.id = existing.id;
    }
    conversationBox.put(conversation);
  }

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

  Stream<List<Conversation>> watchConversations() {
    final queryBuilder = conversationBox.query()
      ..order(Conversation_.lastMessageAt, flags: Order.descending);
    return queryBuilder.watch(triggerImmediately: true).map((q) => q.find());
  }

  // ================== 用户缓存操作 (本次修复重点) ==================

  // 1. 获取用户
  UserEntity? getUser(String userId) {
    final query = userBox.query(UserEntity_.userId.equals(userId)).build();
    final user = query.findFirst();
    query.close();
    return user;
  }

  // 2. 保存单个用户
  void saveUser(UserEntity user) {
    if (user.id == 0) {
      final existing = getUser(user.userId);
      if (existing != null) user.id = existing.id;
    }
    userBox.put(user);
  }

  // 3. 批量保存用户 (UserCacheProvider 需要这个)
  void saveUsers(List<UserEntity> users) {
    store.runInTransaction(TxMode.write, () {
      for (var u in users) {
        if (u.id == 0) {
          // 复用 getUser 查找现有记录 ID
          final existing = getUser(u.userId);
          if (existing != null) u.id = existing.id;
        }
        userBox.put(u);
      }
    });
  }

  // ================== 通用 ==================

  void close() {
    _admin?.close();
    store.close();
  }
}
