import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/repositories/chat_repository.dart'; // ✅ 引入聊天仓库（封装数据逻辑，解耦UI与数据层）
import 'package:flutterchat/providers/conversation_provider.dart'; // 用于刷新会话列表

// Riverpod 代码生成关联文件，通过 build_runner 生成聊天 Provider 实现
part 'chat_provider.g.dart';

/// 聊天会话状态管理 Provider
/// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
/// 【参数说明】
/// - conversationId: 当前会话的唯一标识
/// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
/// 【核心特性】
/// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
/// 2. 自动同步历史消息（进入会话时触发）
/// 3. 实时监听 MQTT 消息（仅处理当前会话）
/// 4. 支持文本/图片消息发送（含状态管理）
@riverpod
class Chat extends _$Chat {
  /// 初始化聊天状态：返回当前会话的实时消息流
  /// 【初始化流程】验证登录状态 → 同步历史消息 → 监听 MQTT 消息 → 提供本地消息流
  @override
  Stream<List<ChatMessage>> build(String conversationId, String recipientId) {
    // 获取聊天仓库实例（封装本地数据库 + 远程 API 操作）
    final chatRepo = ref.watch(chatRepositoryProvider);
    // 获取当前登录用户信息（未登录则返回空流）
    final currentUser = ref.read(currentUserProvider);
    final api = ref.read(apiServiceProvider);
    // 未登录状态：返回空流，避免后续逻辑报错
    if (currentUser == null) return const Stream.empty();

    // 1. 同步历史消息（异步执行，不阻塞 UI 渲染）
    // 调用仓库的同步方法，从远程 API 拉取历史消息到本地数据库

    // 2. 准备头像参数
    final myAvatarUrl = api.getFullAvatarUrl(currentUser.avatarUrl);

    // 3. ✅ 修复：传入 currentUserAvatar
    chatRepo.syncHistory(
      conversationId: conversationId,
      currentUserId: currentUser.userId,
      currentUserAvatar: myAvatarUrl,
    );

    // 2. 启动 MQTT 实时消息监听（仅处理当前会话的消息）
    // 传入会话 ID、当前用户 ID 和仓库实例，用于消息过滤和保存
    _listenMqtt(conversationId, currentUser.userId, chatRepo);

    // 3. 返回本地数据库的实时消息流：数据库数据变化时，UI 自动刷新
    return chatRepo.watchMessages(conversationId);
  }

  /// 📡 监听 MQTT 实时消息（会话级过滤，仅处理当前会话的消息）
  /// 【参数】
  /// - conversationId: 当前会话 ID（用于过滤消息）
  /// - userId: 当前登录用户 ID（用于过滤自己发送的消息）
  /// - repo: 聊天仓库实例（用于保存接收到的消息）
  void _listenMqtt(String conversationId, String userId, ChatRepository repo) {
    // 监听 MQTT 消息流 Provider（来自 services_provider.dart）
    ref.listen(mqttMessageStreamProvider, (previous, next) {
      // 处理 MQTT 消息流数据（next 为 AsyncValue<ChatMessageEvent>）
      next.whenData((mqttEvent) {
        // 过滤：仅处理当前会话的消息（避免接收其他会话的消息）
        if (mqttEvent.conversationId == conversationId) {
          // 调用仓库保存消息：仓库内部会过滤自己发送的消息，避免重复存储
          repo.saveIncomingMessage(mqttEvent, userId);
        }
      });
    });
  }

  /// 📤 发送文本消息
  /// 【参数】text: 待发送的文本内容（自动过滤空文本）
  Future<void> sendText(String text) async {
    // 过滤空文本（避免发送无效消息）
    if (text.trim().isEmpty) return;

    // 获取依赖服务/状态
    final currentUser = ref.read(currentUserProvider)!; // 已在 build 中校验登录，非空
    final chatRepo = ref.read(chatRepositoryProvider); // 聊天仓库实例
    final apiService = ref.read(apiServiceProvider); // API 服务实例（用于获取完整头像 URL）

    // 调用仓库发送文本消息：仓库内部处理乐观更新、网络请求、状态管理
    await chatRepo.sendTextMessage(
      conversationId: conversationId, // 当前会话 ID
      text: text, // 消息内容
      senderId: currentUser.userId, // 发送者 ID（当前用户）
      // 获取完整头像 URL（API 服务提供的全路径转换）
      senderAvatar: apiService.getFullAvatarUrl(currentUser.avatarUrl),
      recipientId: recipientId, // 接收方用户 ID（用于新会话创建）
    );

    // 刷新会话列表：确保会话列表显示最新消息（尤其是新创建的会话）
    ref.invalidate(conversationListProvider);
  }

  /// 📤 发送图片消息
  /// 【参数】image: 从相册/相机选择的图片文件（XFile 为 image_picker 库的文件类型）
  Future<void> sendImage(XFile image) async {
    // 获取依赖服务/状态
    final currentUser = ref.read(currentUserProvider)!;
    final chatRepo = ref.read(chatRepositoryProvider);
    final apiService = ref.read(apiServiceProvider);

    // 调用仓库发送图片消息：仓库内部处理图片上传、乐观更新、状态管理
    await chatRepo.sendImageMessage(
      conversationId: conversationId,
      imageFile: image, // 图片文件
      senderId: currentUser.userId,
      senderAvatar: apiService.getFullAvatarUrl(currentUser.avatarUrl),
      recipientId: recipientId,
    );

    // 刷新会话列表：确保会话列表显示最新消息
    ref.invalidate(conversationListProvider);
  }
}

/// 【设计亮点说明】
/// 1. 仓库模式：通过 `ChatRepository` 封装所有数据逻辑，UI 层仅调用仓库方法，解耦清晰
/// 2. 流驱动：使用 `Stream<List<ChatMessage>>` 作为状态，UI 层通过 `StreamBuilder` 监听，实现实时更新
/// 3. 关注点分离：
///    - Provider 负责状态管理和 UI 交互
///    - Repository 负责数据逻辑（本地数据库 + 远程 API）
///    - Service 负责底层服务（MQTT、API 客户端）
/// 4. 自动资源管理：Riverpod 自动管理 Provider 生命周期，无需手动释放
/// 5. 容错设计：网络异常由仓库统一处理，UI 层仅需处理最终结果
///
/// 【使用示例】
/// ```dart
/// // 在聊天页面中使用
/// final chatAsync = ref.watch(chatProvider(conversationId: '123', recipientId: '456'));
/// chatAsync.when(
///   data: (messages) => ListView.builder(
///     itemCount: messages.length,
///     itemBuilder: (context, index) => ChatMessageItem(message: messages[index]),
///   ),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => Text('加载失败: $e'),
/// );
///
/// // 发送消息
/// final chatNotifier = ref.read(chatProvider(conversationId: '123', recipientId: '456').notifier);
/// chatNotifier.sendText('Hello!');
/// ```
