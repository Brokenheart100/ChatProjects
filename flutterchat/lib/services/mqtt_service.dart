import 'dart:async';
import 'dart:convert';
import 'package:flutterchat/models/chat_message.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:uuid/uuid.dart';

/// MQTT 系统事件模型
/// 承载系统级信令（如连接通知、服务通知、异常提示等）
/// 用于传递非聊天类的系统消息，统一事件格式
class SystemEvent {
  /// 事件类型（如："connect_success"、"error"、"notification" 等，由后端定义）
  final String type;

  /// 事件附加数据（根据事件类型动态变化，如错误信息、通知内容等）
  final Map<String, dynamic> data;

  /// 构造函数：初始化系统事件
  SystemEvent({required this.type, required this.data});

  /// 从 JSON 序列化生成 SystemEvent 实例
  /// 兼容后端返回格式，字段缺失时提供默认值（type默认"UNKNOWN"，data默认空Map）
  factory SystemEvent.fromJson(Map<String, dynamic> json) {
    return SystemEvent(
      type: json['type'] ?? 'UNKNOWN', // 事件类型默认值，避免空指针
      data: json['data'] ?? {}, // 附加数据默认空Map，确保后续操作安全
    );
  }
}

/// MQTT 用户状态事件模型
/// 传递用户在线/离线状态变更信息，用于更新UI层的用户在线状态显示
class UserStatusEvent {
  /// 状态变更的用户ID
  final String userId;

  /// 在线状态（true=在线，false=离线）
  final bool isOnline;

  /// 构造函数：初始化用户状态事件
  UserStatusEvent({required this.userId, required this.isOnline});
}

/// MQTT 聊天消息事件模型
/// 承载MQTT协议接收的原始聊天消息，是后端消息与本地模型的中间载体
/// 提供序列化和模型转换能力，适配本地业务逻辑
class ChatMessageEvent {
  /// 消息发送方用户ID
  final String senderId;

  /// 消息内容（文本消息为文字，图片消息为服务器ObjectKey）
  final String text;

  /// 消息发送时间戳
  final DateTime timestamp;

  /// 消息所属会话ID
  final String conversationId;

  /// 消息唯一标识（后端生成，用于去重和状态追踪）
  final String messageId;

  /// 构造函数：初始化聊天消息事件
  ChatMessageEvent({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.conversationId,
    required this.messageId,
  });

  /// 从 JSON 序列化生成 ChatMessageEvent 实例
  /// 【兼容处理】适配后端不同字段返回格式，字段缺失时提供默认值
  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      senderId: json['senderId'] ?? '', // 发送方ID默认空字符串
      text: json['text'] ?? '', // 消息内容默认空字符串
      // 时间戳解析：优先使用后端返回的"sentAt"，缺失则用当前时间
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      // 会话ID兼容字符串/数字类型（后端可能返回数字ID）
      conversationId: json['conversationId']?.toString() ?? '',
      // 消息ID优先级：先取"messageId" → 再取"id" → 最后生成临时UUID（避免空值）
      messageId: json['messageId']?.toString() ??
          json['id']?.toString() ??
          const Uuid().v4(),
    );
  }

  /// 将 MQTT 原始消息事件转换为本地 ChatMessage 模型
  /// 【核心作用】适配本地数据库存储格式，用于直接入库
  /// [currentUserId]：当前登录用户ID，用于判断消息是否为自己发送（isMe字段）
  ChatMessage toMessage(String currentUserId) {
    return ChatMessage(
      id: 0, // 本地数据库自增ID，初始设为0（入库时自动生成）
      uuid: messageId, // 复用MQTT消息唯一标识（用于去重）
      conversationId: conversationId, // 所属会话ID
      senderId: senderId, // 发送方ID
      text: text, // 消息内容
      isMe: senderId == currentUserId, // 判断是否为当前用户发送的消息
      avatar: '', // 头像留空，由UI层动态加载（避免耦合用户数据）
      contentType: 0, // 消息类型默认0（文本），图片消息会在发送时指定为1
      sentAt: timestamp, // 消息发送时间
      status: 1, // 消息状态默认1（接收成功，因为已通过MQTT接收）
    );
  }
}

// --- MQTT 核心服务类 ---
/// MQTT 消息服务核心类
/// 负责：MQTT服务器连接、主题订阅、消息接收/分发、连接状态管理、资源释放
/// 基于 [mqtt_client] 库封装，对外提供统一的流监听接口（状态流、消息流、系统事件流）
class MqttService {
  /// MQTT 服务器客户端实例（底层核心依赖，负责与服务器通信）
  late final MqttServerClient _client;

  /// 当前登录用户ID（用于生成唯一客户端ID、订阅专属主题）
  final String _userId;

  // 流控制器：用于分发不同类型的事件（广播流支持多订阅者）
  /// 用户状态事件流控制器（分发用户在线/离线状态变更）
  final _statusStreamController = StreamController<UserStatusEvent>.broadcast();

  /// 聊天消息事件流控制器（分发接收的聊天消息）
  final _messageStreamController =
      StreamController<ChatMessageEvent>.broadcast();

  /// 系统事件流控制器（分发系统级信令）
  final _systemStreamController = StreamController<SystemEvent>.broadcast();

  // 对外暴露的可监听流（隐藏流控制器，仅提供只读流，避免外部误操作）
  /// 监听用户状态变更的流（UI层可通过该流更新用户在线状态）
  Stream<UserStatusEvent> get onUserStatusChanged =>
      _statusStreamController.stream;

  /// 监听系统事件的流（UI层可通过该流处理系统通知、异常等）
  Stream<SystemEvent> get onSystemEventReceived =>
      _systemStreamController.stream;

  /// 监听聊天消息的流（聊天页面通过该流接收实时消息）
  Stream<ChatMessageEvent> get onMessageReceived =>
      _messageStreamController.stream;

  /// 构造函数：初始化MQTT客户端配置
  /// [serverAddress]：MQTT服务器地址（如："192.168.1.100"、"mqtt.example.com"）
  /// [userId]：当前登录用户ID（用于生成唯一客户端ID和订阅专属主题）
  MqttService({required String serverAddress, required String userId})
      : _userId = userId {
    if (serverAddress.isEmpty) return;
    logger.d(
        "🔧 [MQTT] 初始化客户端 | ClientID=flutter_client_$_userId | Host=$serverAddress");

    // 初始化MQTT服务器客户端
    _client = MqttServerClient(serverAddress, 'flutter_client_$_userId');
    _client.port = 1883; // MQTT默认端口（TCP连接）
    _client.logging(on: false); // 关闭底层库日志，使用自定义日志系统（带Emoji标识）
    _client.keepAlivePeriod = 60; // 心跳周期60秒（维持连接，避免被服务器断开）

    // 绑定核心回调函数（连接成功、断开连接、订阅成功时触发）
    _client.onConnected = _onConnected; // 连接成功回调
    _client.onDisconnected = _onDisconnected; // 断开连接回调
    _client.onSubscribed = _onSubscribed; // 订阅主题成功回调
  }

  /// 连接MQTT服务器
  /// 【注意】异步操作，连接结果通过回调函数（_onConnected/_onDisconnected）反馈
  Future<void> connect() async {
    if (_userId.isEmpty) return;
    try {
      logger.i(
          "🔌 [MQTT] 正在连接服务器... | Host=${_client.server} | Port=${_client.port}");
      await _client.connect(); // 发起连接请求
    } catch (e) {
      // 连接异常（如：服务器不可达、网络错误、端口占用等）
      logger.e('❌ [MQTT] 连接失败', error: e);
      _client.disconnect(); // 异常时主动断开连接，清理资源
    }
  }

  /// MQTT 连接成功回调函数
  /// 【核心逻辑】连接成功后执行：订阅必要主题 + 监听消息接收
  void _onConnected() {
    logger.i('🟢 [MQTT] 连接服务器成功！');

    // 1. 订阅核心主题（根据业务需求定义，与后端约定）
    _subscribeTopic('users/$_userId/messages'); // 当前用户的专属消息主题（点对点消息）
    _subscribeTopic('chats/+/messages'); // 所有聊天会话的消息主题（群聊/私聊通用，+为通配符）
    _subscribeTopic('users/$_userId/system'); // 当前用户的系统事件主题（系统信令）
    _subscribeTopic('users/$_userId/status'); // 当前用户的状态变更主题（在线/离线通知）

    // 2. 监听MQTT消息更新（服务器推送消息时触发）
    // _client.updates 为消息流，包含所有订阅主题的接收消息
    _client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      // 解析消息（messages为消息列表，取第一个元素即可，单条消息场景）
      final MqttPublishMessage receivedMessage =
          messages![0].payload as MqttPublishMessage;
      final String topic = messages[0].topic; // 消息所属主题（用于分流）
      // 解析消息体（将字节数组转换为字符串）
      final String payload = MqttPublishPayload.bytesToStringAsString(
          receivedMessage.payload.message);

      // 打印原始消息日志（方便调试，包含主题和消息体）
      logger.d("📨 [MQTT 接收消息] | 主题: $topic\n📦 内容: $payload");

      try {
        // 将JSON字符串解析为Map（后端消息统一JSON格式）
        final Map<String, dynamic> jsonData = jsonDecode(payload);

        // ✅ 消息分流逻辑（根据主题类型分发到对应流）
        if (topic.contains('/status')) {
          // 分流：用户状态变更消息
          final String targetUserId = jsonData['userId'];
          final bool isOnline =
              jsonData['status'] == 'online'; // 后端用"online"/"offline"表示状态

          logger.i(
              "🚦 [MQTT 用户状态] | 用户: ${targetUserId.substring(0, 5)}... | 状态: ${isOnline ? '🟢 在线' : '⚫ 离线'}");
          // 发送到状态流，UI层监听后更新
          _statusStreamController.add(UserStatusEvent(
            userId: targetUserId,
            isOnline: isOnline,
          ));
        } else if (topic.contains('/system')) {
          // 分流：系统事件消息
          final SystemEvent systemEvent = SystemEvent.fromJson(jsonData);
          logger.i(
              "⚙️ [MQTT 系统事件] | 类型: ${systemEvent.type} | 数据: ${systemEvent.data}");
          // 发送到系统事件流
          _systemStreamController.add(systemEvent);
        } else {
          // 分流：聊天消息（默认分支，处理所有聊天相关消息）
          final ChatMessageEvent chatEvent =
              ChatMessageEvent.fromJson(jsonData);
          logger.i(
              "💬 [MQTT 聊天消息] | 发送方: ${chatEvent.senderId.substring(0, 5)}... | 内容: ${chatEvent.text}");
          // 发送到聊天消息流，聊天页面监听后处理
          _messageStreamController.add(chatEvent);
        }
      } catch (e) {
        // 消息解析失败（如：JSON格式错误、字段缺失）
        logger.e('💥 [MQTT 消息解析失败] | 原始内容: $payload | 错误: $e');
      }
    });
  }

  /// 订阅MQTT主题
  /// [topic]：要订阅的主题名称（与后端约定格式）
  /// QoS等级：MqttQos.atLeastOnce（至少一次送达，确保消息不丢失，适合聊天场景）
  void _subscribeTopic(String topic) {
    logger.d("🔗 [MQTT 订阅主题] | 主题: $topic");
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  /// 订阅主题成功回调函数
  /// [topic]：成功订阅的主题名称（用于日志确认）
  void _onSubscribed(String topic) {
    logger.d("✅ [MQTT 订阅成功] | 主题: $topic");
  }

  /// MQTT 断开连接回调函数
  /// （触发场景：网络中断、服务器主动断开、调用dispose方法）
  void _onDisconnected() {
    logger.w("🔴 [MQTT] 连接已断开");
  }

  /// 销毁MQTT服务，释放资源
  /// 【必须调用】在页面销毁或退出登录时调用，避免内存泄漏和无效连接
  void dispose() {
    if (_userId.isEmpty) return;
    logger.w("🛑 [MQTT] 正在销毁服务，释放资源...");
    // 关闭所有流控制器（避免流泄漏）
    _statusStreamController.close();
    _messageStreamController.close();
    _systemStreamController.close();
    // 断开MQTT连接（告知服务器释放客户端资源）
    _client.disconnect();
  }
}

/// 【核心设计说明】
/// 1. 分层设计：事件模型（数据载体）+ 服务类（通信逻辑），职责分离
/// 2. 流驱动：通过广播流对外提供监听接口，UI层无需直接操作MQTT客户端，解耦
/// 3. 容错设计：消息解析失败、连接异常时仅打日志，不崩溃，保证应用稳定性
/// 4. 约定优先：主题格式、消息JSON结构需与后端严格约定（如：/users/{userId}/messages）
/// 5. 资源管理：dispose方法必须手动调用，确保流和连接资源释放
///
/// 【MQTT QoS等级说明】
/// - MqttQos.atLeastOnce：至少一次送达（服务器确保消息到达，可能重复，适合聊天消息）
/// - 其他等级：atMostOnce（最多一次，可能丢失）、exactlyOnce（恰好一次，性能开销大）
///
/// 【主题格式说明】
/// - 个人专属主题：users/{userId}/xxx（仅当前用户订阅，接收点对点消息/系统通知）
/// - 公共聊天主题：chats/{conversationId}/messages（群聊/私聊通用，按会话ID订阅）
/// - 通配符：+ 表示单层通配符（如 chats/+/messages 匹配 chats/123/messages、chats/456/messages）
