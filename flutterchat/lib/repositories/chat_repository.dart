import 'package:flutterchat/objectbox.g.dart'; // ObjectBox 数据库生成文件
import 'package:image_picker/image_picker.dart'; // 图片选择器，用于处理图片上传
import 'package:uuid/uuid.dart'; // UUID 生成器，用于创建唯一消息ID
import 'package:riverpod_annotation/riverpod_annotation.dart'; // Riverpod 注解，用于依赖注入
import 'package:flutterchat/models/chat_message.dart'; // 聊天消息模型
import 'package:flutterchat/services/api_service.dart'; // API 服务，处理网络请求
import 'package:flutterchat/services/objectbox_service.dart'; // ObjectBox 服务，处理本地数据库操作
import 'package:flutterchat/providers/services_provider.dart'; // 服务提供者，用于获取其他服务实例
import 'package:flutterchat/services/logger_service.dart'; // 日志服务，用于记录日志
import 'package:flutterchat/services/mqtt_service.dart'; // MQTT 服务，处理实时消息推送

// 生成 Riverpod 相关代码的部分标记
part 'chat_repository.g.dart';

/// ChatRepository 的 Riverpod Provider，使用 keepAlive 确保实例持久化
/// 作用：提供全局唯一的 ChatRepository 实例，便于其他组件注入使用
@Riverpod(keepAlive: true)
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(
    api: ref.watch(apiServiceProvider), // 从依赖注入获取 ApiService 实例
    db: ref.watch(objectBoxProvider), // 从依赖注入获取 ObjectBoxService 实例
  );
}

/// 聊天数据仓库类，负责处理聊天消息的所有业务逻辑
/// 包括：消息监听、历史同步、消息发送、接收消息处理等
class ChatRepository {
  // 私有成员变量，通过构造函数注入
  final ApiService _api; // API 服务实例，用于网络请求
  final ObjectBoxService _db; // 本地数据库服务实例，用于消息持久化

  /// 构造函数，初始化依赖服务
  /// [api]：API 服务实例
  /// [db]：ObjectBox 数据库服务实例
  ChatRepository({
    required ApiService api,
    required ObjectBoxService db,
  })  : _api = api,
        _db = db;

  /// 监听指定会话的消息流
  /// [conversationId]：会话ID，用于筛选指定会话的消息
  /// 返回值：包含指定会话所有消息的 Stream，支持实时更新
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _db.watchMessages(conversationId); // 调用数据库服务的监听方法
  }

  /// 同步消息历史记录
  /// 作用：从服务器获取历史消息，与本地消息合并，处理乐观更新的消息
  /// [conversationId]：会话ID
  /// [currentUserId]：当前用户ID，用于区分自己发送的消息
  /// [currentUserAvatar]：当前用户头像，用于补全远程消息的头像信息
  Future<void> syncHistory({
    required String conversationId,
    required String currentUserId,
    required String currentUserAvatar,
  }) async {
    try {
      // 从 API 获取指定会话的历史消息
      final history = await _api.getMessageHistory(
        conversationId,
        currentUserId: currentUserId,
      );

      // 如果历史消息为空，直接返回
      if (history.isEmpty) return;

      // 查询本地数据库中该会话的所有消息
      final localMessages = _db.messageBox
          .query(ChatMessage_.conversationId.equals(conversationId))
          .build()
          .find();

      // 将本地消息转换为 Map，便于根据 UUID 快速查找
      final localMap = {for (var m in localMessages) m.uuid: m};

      // 存储需要保存到本地的消息列表
      final List<ChatMessage> toSave = [];

      // 遍历远程历史消息，处理每条消息
      for (var remoteMsg in history) {
        // 如果是他人发送的消息
        if (remoteMsg.senderId != currentUserId) {
          // 如果本地没有该消息，添加到保存列表
          if (!localMap.containsKey(remoteMsg.uuid)) {
            toSave.add(remoteMsg);
          }
          continue; // 跳过后续处理，继续下一条
        }

        // 如果是自己发送的消息，且本地已存在该消息，跳过
        if (localMap.containsKey(remoteMsg.uuid)) {
          continue;
        }

        // 获取远程消息中的客户端临时ID（乐观更新时使用）
        final tempUuid = remoteMsg.clientMessageId;
        // 如果存在临时ID，且本地有对应的乐观更新消息
        if (tempUuid != null && localMap.containsKey(tempUuid)) {
          // 获取本地乐观更新的消息
          final localOptimisticMsg = localMap[tempUuid]!;

          // 记录日志：发现乐观更新消息，执行合并
          logger.i("🔄 [Repo] 发现乐观更新消息，执行合并: $tempUuid -> ${remoteMsg.uuid}");

          // 更新本地消息的 UUID 为后端返回的正式ID
          localOptimisticMsg.uuid = remoteMsg.uuid;
          // 更新消息状态为已发送成功（1）
          localOptimisticMsg.status = 1;
          // 更新消息发送时间为后端返回的时间
          localOptimisticMsg.sentAt = remoteMsg.sentAt;

          // 将更新后的消息添加到保存列表
          toSave.add(localOptimisticMsg);
        } else {
          // 如果没有临时ID或本地没有对应消息，补全头像信息后保存
          remoteMsg.avatar = currentUserAvatar;
          toSave.add(remoteMsg);
        }
      }

      // 如果有需要保存的消息，批量保存到本地数据库
      if (toSave.isNotEmpty) {
        _db.saveMessages(toSave);
        // 记录日志：同步更新的消息数量
        logger.d("✅ [Repo] 同步更新了 ${toSave.length} 条消息");
      }
    } catch (e) {
      // 记录历史同步失败的日志
      logger.w("⚠️ [Repo] 历史同步失败: $e");
    }
  }

  /// 发送文本消息
  /// [conversationId]：会话ID
  /// [text]：消息文本内容
  /// [senderId]：发送者ID
  /// [senderAvatar]：发送者头像
  /// [recipientId]：接收者ID
  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderId,
    required String senderAvatar,
    required String recipientId,
  }) async {
    // 生成客户端临时UUID（用于乐观更新）
    final tempUuid = const Uuid().v4();

    // 创建待发送的临时消息（乐观更新）
    final pendingMessage = ChatMessage(
      id: 0, // 本地数据库ID，初始为0，由数据库自动生成
      uuid: tempUuid, // 使用临时UUID
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      isMe: true, // 标记为自己发送的消息
      avatar: senderAvatar,
      contentType: 0, // 文本消息类型
      sentAt: DateTime.now(), // 当前时间作为发送时间
      status: 0, // 状态为发送中（0）
    );
    // 将临时消息保存到本地数据库（乐观更新，立即显示）
    _db.saveMessage(pendingMessage);

    try {
      // 调用API发送消息
      final response = await _api.sendMessage(
        conversationId,
        text,
        contentType: 0, // 文本消息类型
        recipientId: recipientId,
        localId: tempUuid, // 传入客户端临时ID，用于后端关联
      );

      // 更新消息的UUID为后端返回的正式ID
      pendingMessage.uuid = response.backendMessageId;
      // 更新会话ID为后端返回的真实会话ID（可能是新会话）
      pendingMessage.conversationId = response.realConversationId;
      // 更新消息状态为已发送成功（1）
      pendingMessage.status = 1;

      // 将更新后的消息保存到本地数据库
      _db.saveMessage(pendingMessage);
    } catch (e) {
      // 记录发送失败日志
      logger.e("❌ [Repo] 发送文本失败", error: e);
      // 更新消息状态为发送失败（2）
      _db.saveMessage(pendingMessage.copyWith(status: 2));
      // 重新抛出异常，让调用者处理
      rethrow;
    }
  }

  /// 发送图片消息
  /// 核心流程：上传图片 -> 保存本地乐观更新 -> 调用发送API -> 更新消息状态
  /// [conversationId]：会话ID
  /// [imageFile]：图片文件对象
  /// [senderId]：发送者ID
  /// [senderAvatar]：发送者头像
  /// [recipientId]：接收者ID
  Future<void> sendImageMessage({
    required String conversationId,
    required XFile imageFile,
    required String senderId,
    required String senderAvatar,
    required String recipientId,
  }) async {
    String imageObjectKey;
    try {
      // 上传图片到服务器，获取图片对象键
      imageObjectKey = await _api.uploadFileAndGetObjectKey(imageFile);
    } catch (e) {
      // 记录图片上传失败日志
      logger.e("❌ [Repo] 图片上传失败", error: e);
      // 抛出友好错误信息
      throw "图片上传失败，请检查网络";
    }

    // 生成客户端临时UUID（用于乐观更新）
    final tempUuid = const Uuid().v4();

    // 创建待发送的临时图片消息（乐观更新）
    final pendingMessage = ChatMessage(
      id: 0,
      uuid: tempUuid,
      conversationId: conversationId,
      senderId: senderId,
      text: imageObjectKey, // 图片对象键作为消息文本存储
      isMe: true,
      avatar: senderAvatar,
      contentType: 1, // 图片消息类型
      sentAt: DateTime.now(),
      status: 0, // 发送中状态
    );
    // 将临时消息保存到本地数据库（乐观更新）
    _db.saveMessage(pendingMessage);

    try {
      // 调用API发送图片消息
      final response = await _api.sendMessage(
        conversationId,
        imageObjectKey,
        contentType: 1, // 图片消息类型
        recipientId: recipientId,
        localId: tempUuid, // 传入客户端临时ID
      );

      // 检查会话ID是否变化（新会话场景）
      if (response.realConversationId != conversationId) {
        // 更新消息的会话ID为后端返回的真实会话ID
        pendingMessage.conversationId = response.realConversationId;
      }

      // 更新消息UUID为后端返回的正式ID
      pendingMessage.uuid = response.backendMessageId;
      // 更新消息状态为已发送成功（1）
      pendingMessage.status = 1;

      // 将更新后的消息保存到本地数据库
      _db.saveMessage(pendingMessage);
    } catch (e) {
      // 记录发送失败日志
      logger.e("❌ [Repo] 发送图片协议失败", error: e);
      // 更新消息状态为发送失败（2）
      _db.saveMessage(pendingMessage.copyWith(status: 2));
      // 重新抛出异常
      rethrow;
    }
  }

  /// 保存接收到的MQTT消息
  /// [event]：MQTT消息事件，包含消息内容、发送者等信息
  /// [currentUserId]：当前用户ID，用于过滤自己发送的消息
  void saveIncomingMessage(ChatMessageEvent event, String currentUserId) {
    // 标准化发送者ID和当前用户ID（去除空格，转为小写），避免大小写或空格导致的匹配错误
    final incomingId = event.senderId.trim().toLowerCase();
    final myId = currentUserId.trim().toLowerCase();

    // 如果是自己发送的消息，直接拦截（避免重复处理）
    if (incomingId == myId) {
      logger.d("✋ [Repo] 拦截到自己发送的 MQTT 消息");
      return;
    }

    // 创建接收消息对象
    final incomingMessage = ChatMessage(
      id: 0,
      uuid: event.messageId, // 使用MQTT消息中的唯一ID
      conversationId: event.conversationId,
      senderId: event.senderId,
      text: event.text,
      isMe: false, // 标记为他人发送的消息
      avatar: '', // 初始头像为空，后续可通过其他逻辑补全
      contentType: 0, // 默认文本消息类型，可根据实际情况扩展
      sentAt: event.timestamp, // 使用MQTT消息中的时间戳
      status: 1, // 接收的消息状态直接为已接收（1）
    );

    // 将消息保存到本地数据库
    _db.saveMessage(incomingMessage);
    // 记录日志：MQTT消息入库成功
    logger.d("📥 [Repo] MQTT 消息入库成功");
  }
}
