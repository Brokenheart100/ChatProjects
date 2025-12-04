import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/objectbox_service.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:flutterchat/services/mqtt_service.dart'; // 引入 MQTT 消息事件模型

part 'chat_repository.g.dart';

/// 聊天数据仓库 Provider
/// 提供全局单例的聊天仓库实例，封装聊天相关的所有数据操作（本地数据库 + 远程 API）
/// keepAlive: true 确保仓库实例全局复用，避免频繁创建销毁，提高性能
@Riverpod(keepAlive: true)
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(
    api: ref.watch(apiServiceProvider), // 注入 API 服务依赖（远程数据操作）
    db: ref.watch(objectBoxProvider), // 注入 ObjectBox 服务依赖（本地数据操作）
  );
}

/// 聊天数据仓库核心类
/// 【职责】封装聊天相关的所有数据逻辑，作为 UI 层与数据层的中间层
/// 【设计原则】
/// 1. 单一职责：仅处理聊天数据，不涉及 UI 逻辑
/// 2. 数据隔离：UI 层仅通过仓库访问数据，不直接操作 API/数据库
/// 3. 统一接口：提供清晰的方法，隐藏底层实现细节（API/数据库的切换对 UI 透明）
/// 4. 错误处理：集中处理数据操作异常，提供友好的错误反馈
class ChatRepository {
  /// 远程 API 服务实例（用于网络请求，如发送消息、同步历史）
  final ApiService _api;

  /// 本地数据库服务实例（用于数据持久化，如存储消息、读取历史）
  final ObjectBoxService _db;

  /// 构造函数：注入依赖服务
  /// 【依赖注入】通过构造函数注入 API 和数据库服务，便于测试和替换实现
  ChatRepository({
    required ApiService api,
    required ObjectBoxService db,
  })  : _api = api,
        _db = db;

  // ==========================================
  // 1. 读取数据 (Read) - 本地数据库 + 远程同步
  // ==========================================

  /// 监听指定会话的消息流（用于 UI 实时刷新）
  /// 【返回】本地数据库的实时消息流，当数据库中该会话的消息变化时，流会自动更新
  /// 【使用场景】聊天页面通过 StreamBuilder 监听此流，实现消息的实时显示
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _db.watchMessages(conversationId);
  }

  /// 同步指定会话的历史消息（从远程 API 拉取到本地数据库）
  /// 【触发时机】通常在用户进入会话时调用，确保本地消息完整
  /// 【容错设计】同步失败不阻断用户使用，仅记录日志（允许离线使用本地数据）
  /// 【参数】
  /// - conversationId: 目标会话 ID
  /// - currentUserId: 当前登录用户 ID（用于 API 权限验证）
  Future<void> syncHistory({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      // 1. 从远程 API 拉取历史消息
      final historyMessages = await _api.getMessageHistory(
        conversationId,
        currentUserId: currentUserId, // 传入当前用户 ID，确保 API 权限正确
      );

      // 2. 数据持久化：将拉取的历史消息存入本地数据库
      // ObjectBox 会根据消息的 uuid 自动去重，避免重复存储
      if (historyMessages.isNotEmpty) {
        _db.saveMessages(historyMessages);
        logger.d(
            "✅ [聊天仓库] 成功同步 ${historyMessages.length} 条历史消息（会话ID：$conversationId）");
      }
    } catch (e) {
      // 同步失败处理：仅记录日志，不抛出异常（允许离线使用本地已有消息）
      logger.w("⚠️ [聊天仓库] 历史消息同步失败（可能是离线状态）：$e");
    }
  }

  // ==========================================
  // 2. 发送数据 (Write) - 乐观更新 + 网络请求
  // ==========================================

  /// 发送文本消息（含乐观更新、状态管理、异常处理）
  /// 【核心流程】乐观更新 → 网络请求 → 更新状态（成功/失败）
  /// 【参数】
  /// - conversationId: 目标会话 ID
  /// - text: 待发送的文本内容
  /// - senderId: 发送者用户 ID（当前登录用户）
  /// - senderAvatar: 发送者头像 URL（用于本地显示，避免 UI 闪烁）
  /// - recipientId: 接收者用户 ID（用于新会话创建时的 ID 修正）
  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String senderId,
    required String senderAvatar,
    required String recipientId,
  }) async {
    // 1. 生成临时 UUID（用于本地消息唯一标识，后续无需修改）
    final tempUuid = const Uuid().v4();

    // 2. 乐观更新（Optimistic Update）：立即存入本地数据库
    // 目的：提升用户体验，消息发送后立即显示在 UI 上，无需等待网络响应
    final pendingMessage = ChatMessage(
      id: 0, // 本地数据库自增 ID，初始设为 0（入库时自动生成）
      uuid: tempUuid, // 临时唯一标识，用于后续状态更新
      conversationId: conversationId, // 目标会话 ID
      senderId: senderId, // 发送者 ID
      text: text, // 消息内容
      isMe: true, // 自己发送的消息
      avatar: senderAvatar, // 发送者头像（立即显示，避免 UI 闪烁）
      contentType: 0, // 消息类型：0=文本
      sentAt: DateTime.now(), // 发送时间（本地当前时间）
      status: 0, // 消息状态：0=发送中
    );
    _db.saveMessage(pendingMessage); // 存入本地数据库，UI 立即刷新

    try {
      // 3. 发起网络请求：调用 API 发送消息
      final realConversationId = await _api.sendMessage(
        conversationId, // 目标会话 ID
        text, // 消息内容
        contentType: 0, // 消息类型：0=文本
        recipientId: recipientId, // 接收者 ID（用于新会话创建）
      );

      // 4. 成功处理：更新消息状态为"发送成功"
      // 会话 ID 修正逻辑：针对新创建的私聊，后端可能返回真实会话 ID
      if (realConversationId != conversationId) {
        // 新会话场景：后端返回真实会话 ID，需修正本地消息的会话归属
        logger.i(
            "🔀 [聊天仓库] 会话 ID 修正：临时 ID $conversationId → 真实 ID $realConversationId");
        _db.saveMessage(pendingMessage.copyWith(
          conversationId: realConversationId, // 更新为真实会话 ID
          status: 1, // 消息状态：1=发送成功
        ));
        // 注意：会话列表的刷新由外部 Provider（如 conversationListProvider）负责
      } else {
        // 普通场景：会话 ID 不变，仅更新消息状态
        _db.saveMessage(pendingMessage.copyWith(status: 1));
      }
    } catch (e) {
      // 5. 失败处理：更新消息状态为"发送失败"，并抛出异常（让 UI 层显示错误提示）
      logger.e("❌ [聊天仓库] 发送文本消息失败（消息ID：$tempUuid）", error: e);
      _db.saveMessage(pendingMessage.copyWith(status: 2)); // 消息状态：2=发送失败
      rethrow; // 抛出异常，让 UI 层捕获并显示 Toast 等错误提示
    }
  }

  /// 发送图片消息（流程与文本消息类似，多了图片上传步骤）
  /// 【核心流程】图片上传 → 乐观更新 → 发送业务消息 → 更新状态
  /// 【参数】
  /// - conversationId: 目标会话 ID
  /// - imageFile: 从相册/相机选择的图片文件（XFile 为 image_picker 库类型）
  /// - senderId: 发送者用户 ID
  /// - senderAvatar: 发送者头像 URL
  /// - recipientId: 接收者用户 ID
  Future<void> sendImageMessage({
    required String conversationId,
    required XFile imageFile,
    required String senderId,
    required String senderAvatar,
    required String recipientId,
  }) async {
    // 1. 图片上传：先将图片上传到服务器，获取唯一标识（ObjectKey）
    // 注意：图片上传是前置步骤，失败则直接抛出异常，不创建消息
    String imageObjectKey;
    try {
      // 调用 API 上传图片，返回服务器生成的 ObjectKey（用于后续加载图片）
      imageObjectKey = await _api.uploadFileAndGetObjectKey(imageFile);
    } catch (e) {
      logger.e("❌ [聊天仓库] 图片上传失败", error: e);
      throw "图片上传失败，请检查网络"; // 抛出友好错误信息，让 UI 层显示
    }

    // 2. 生成临时 UUID（用于本地消息唯一标识）
    final tempUuid = const Uuid().v4();

    // 3. 乐观更新：立即存入本地数据库，显示"发送中"状态
    final pendingMessage = ChatMessage(
      id: 0,
      uuid: tempUuid,
      conversationId: conversationId,
      senderId: senderId,
      text: imageObjectKey, // 图片消息的内容存储服务器返回的 ObjectKey（用于加载图片）
      isMe: true,
      avatar: senderAvatar,
      contentType: 1, // 消息类型：1=图片
      sentAt: DateTime.now(),
      status: 0, // 发送中
    );
    _db.saveMessage(pendingMessage); // 存入本地数据库，UI 立即刷新

    try {
      // 4. 发送图片业务消息：告知服务器图片的 ObjectKey，让接收方加载
      final realConversationId = await _api.sendMessage(
        conversationId,
        imageObjectKey, // 消息内容为图片 ObjectKey
        contentType: 1, // 消息类型：1=图片
        recipientId: recipientId,
      );

      // 5. 成功处理：更新消息状态为"发送成功"，并处理会话 ID 修正
      if (realConversationId != conversationId) {
        _db.saveMessage(pendingMessage.copyWith(
          conversationId: realConversationId,
          status: 1, // 发送成功
        ));
      } else {
        _db.saveMessage(pendingMessage.copyWith(status: 1));
      }
    } catch (e) {
      // 6. 失败处理：更新消息状态为"发送失败"，并抛出异常
      logger.e("❌ [聊天仓库] 发送图片消息失败（消息ID：$tempUuid）", error: e);
      _db.saveMessage(pendingMessage.copyWith(status: 2)); // 发送失败
      rethrow; // 抛出异常，让 UI 层显示错误提示
    }
  }

  // ==========================================
  // 3. 处理外部输入 (MQTT) - 消息过滤 + 入库
  // ==========================================

  /// 保存从 MQTT 接收到的消息（过滤自己发送的消息，避免重复）
  /// 【触发时机】MQTT 服务接收到新消息时调用
  /// 【参数】
  /// - event: MQTT 原始消息事件（包含发送者、内容、时间戳等）
  /// - currentUserId: 当前登录用户 ID（用于过滤自己发送的消息）
  void saveIncomingMessage(ChatMessageEvent event, String currentUserId) {
    // 过滤自己发送的消息：避免重复存储（自己发送的消息已通过 sendTextMessage/sendImageMessage 存入）
    final incomingId = event.senderId.trim().toLowerCase();
    final myId = currentUserId.trim().toLowerCase();

    // 2. 打印看看现在一样了吗
    // logger.d("🔍 [比对] $incomingId vs $myId");

    if (incomingId == myId) {
      logger.d("✋ [Repo] 拦截到自己发送的 MQTT 消息");
      return;
    }

    // 构造本地聊天消息模型（适配本地数据库结构）
    final incomingMessage = ChatMessage(
      id: 0, // 本地自增 ID，初始设为 0
      uuid: event.messageId, // 复用 MQTT 消息的唯一标识（用于去重）
      conversationId: event.conversationId, // 所属会话 ID
      senderId: event.senderId, // 发送者 ID
      text: event.text, // 消息内容（文本/图片 ObjectKey）
      isMe: false, // 对方发送的消息
      avatar: '', // 头像留空，由 UI 层通过 UserProfileProvider 动态加载（避免耦合用户数据）
      contentType: 0, // 消息类型默认 0（文本），需根据实际 MQTT 事件扩展支持图片类型
      sentAt: event.timestamp, // 消息发送时间（来自 MQTT 事件）
      status: 1, // 消息状态：1=接收成功（已通过 MQTT 接收，确保送达）
    );

    // 存入本地数据库：触发 watchMessages 流更新，UI 自动刷新显示新消息
    _db.saveMessage(incomingMessage);
    logger.d(
        "📥 [聊天仓库] MQTT 消息入库成功：${incomingMessage.text}（会话ID：${incomingMessage.conversationId}）");
  }
}

/// 【消息状态码说明】
/// 0: 发送中 → UI 显示加载动画
/// 1: 发送成功 → UI 显示已送达标识
/// 2: 发送失败 → UI 显示失败图标，支持重试
///
/// 【设计亮点】
/// 1. 乐观更新：优先更新本地 UI，提升用户体验
/// 2. 数据隔离：UI 层仅通过仓库访问数据，不直接操作 API/数据库
/// 3. 容错设计：网络异常时更新状态，支持离线使用
/// 4. 统一接口：隐藏底层实现细节，便于后续替换 API/数据库
/// 5. 清晰分层：职责明确，便于维护和扩展
///
/// 【使用建议】
/// - 聊天页面通过 `chatRepositoryProvider` 获取仓库实例
/// - 监听 `watchMessages` 流实现消息实时更新
/// - 调用 `sendTextMessage`/`sendImageMessage` 发送消息
/// - 进入会话时调用 `syncHistory` 同步历史消息
/// - MQTT 服务接收到消息时调用 `saveIncomingMessage` 处理
