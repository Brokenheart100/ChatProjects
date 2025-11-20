import 'dart:async';
// 导入flutter_bloc核心库，用于状态管理（Bloc模式）
import 'package:flutter_bloc/flutter_bloc.dart';
// 导入聊天消息模型类（定义消息的结构：是否自己发送、内容、类型等）
import 'package:flutterchat/models/chat_message.dart';
// 导入API服务类（封装与后端的HTTP交互：获取历史消息、发送消息等）
import 'package:flutterchat/services/api_service.dart';
// 导入日志服务类（用于打印调试/错误日志）
import 'package:flutterchat/services/logger_service.dart';
// 导入MQTT服务类（用于实时接收消息的长连接服务）
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:image_picker/image_picker.dart';
// 导入聊天相关的事件类（定义所有可能触发的事件：初始化、发送文本、接收消息等）
import 'chat_event.dart';
// 导入聊天相关的状态类（定义UI需要的状态数据：消息列表、加载状态、错误信息等）
import 'chat_state.dart';

export 'chat_event.dart';
export 'chat_state.dart';

// --- Event ---
abstract class ChatEvent {}

class ChatStarted extends ChatEvent {}

class ChatTextMessageSent extends ChatEvent {
  final String text;
  ChatTextMessageSent(this.text);
}

class ChatImageSent extends ChatEvent {
  final XFile image;
  ChatImageSent(this.image);
}

class ChatNewMessageReceived extends ChatEvent {
  final ChatMessage message;
  ChatNewMessageReceived(this.message);
}

// --- State ---
enum ChatStatus { initial, loading, success, failure }

class ChatState {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  ChatState(
      {this.status = ChatStatus.initial,
      this.messages = const [],
      this.isSending = false,
      this.errorMessage});

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

/// 聊天模块的业务逻辑核心（Bloc）
/// 负责处理所有聊天相关事件，维护聊天状态，并将状态变更通知给UI
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // API服务实例（通过构造函数注入，便于测试和替换）
  final ApiService _apiService;
  // MQTT服务实例（可选，可能为null，通过构造函数注入）
  final MqttService? _mqttService;
  // 当前聊天会话的ID（与谁聊天的标识）
  final String _conversationId;
  // 当前登录用户的ID（用于区分消息是否是自己发送的）
  final String _currentUserId;

  // MQTT消息订阅的流订阅对象（用于后续取消订阅，防止内存泄漏）
  StreamSubscription? _mqttSubscription;

  /// 构造函数：初始化依赖和初始状态
  /// [apiService]：后端交互服务
  /// [mqttService]：实时消息服务
  /// [conversationId]：当前聊天对象ID
  /// [currentUserId]：当前用户ID
  ChatBloc({
    required ApiService apiService,
    required MqttService? mqttService,
    required String conversationId,
    required String currentUserId,
  })  : _apiService = apiService,
        _mqttService = mqttService,
        _conversationId = conversationId,
        _currentUserId = currentUserId,
        // 初始状态：空消息列表、默认状态（未加载）
        super(ChatState()) {
    // 注册事件与处理函数的映射：当某个事件触发时，调用对应的处理方法
    on<ChatStarted>(_onStarted); // 初始化事件（加载历史消息）
    on<ChatTextMessageSent>(_onTextSent); // 发送文本消息事件
    on<ChatImageSent>(_onImageSent); // 发送图片消息事件
    on<ChatNewMessageReceived>(_onMessageReceived); // 收到新消息事件

    // --- 核心逻辑：监听MQTT实时消息 ---
    if (_mqttService != null) {
      // 订阅MQTT服务的消息接收流，当有新消息时触发回调
      _mqttSubscription = _mqttService!.onMessageReceived.listen((event) {
        // 过滤消息：只处理当前聊天对象发送的消息，或自己在其他设备发送的消息（多端同步）
        if (event.senderId == _conversationId ||
            event.senderId == _currentUserId) {
          // 将MQTT事件转换为本地ChatMessage模型
          final msg = ChatMessage(
            isMe: event.senderId == _currentUserId, // 是否自己发送
            sender: event.senderId, // 发送者ID（后续可优化为昵称）
            text: event.text, // 消息内容
            avatar: '', // 头像暂为空，后续可从用户信息缓存中获取
            contentType: 0, // 0表示文本类型（MQTT当前只处理文本，可扩展）
          );
          // 触发内部事件：通知Bloc有新消息需要处理（最终会更新状态）
          add(ChatNewMessageReceived(msg));
        }
      });
    }
  }

  /// 处理【聊天初始化事件】（ChatStarted）
  /// 触发时机：进入聊天页面时，加载历史消息
  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    // 1. 更新状态为"加载中"（UI可显示加载动画）
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      // 2. 调用API获取历史消息
      final history = await _apiService.getMessageHistory(
        _conversationId, // 聊天对象ID
        currentUserId: _currentUserId, // 当前用户ID（用于区分消息归属）
      );
      // 3. 加载成功：更新状态为"成功"，并设置历史消息列表
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: history,
      ));
    } catch (e) {
      // 4. 加载失败：打印日志，特殊处理（新会话可能无历史消息，故显示空列表而非错误页）
      logger.w("加载历史消息失败: $e");
      emit(state.copyWith(
        status: ChatStatus.success,
        messages: [], // 失败时显示空列表
      ));
    }
  }

  /// 处理【发送文本消息事件】（ChatTextMessageSent）
  Future<void> _onTextSent(
      ChatTextMessageSent event, Emitter<ChatState> emit) async {
    // 过滤空消息（避免发送空白内容）
    if (event.text.trim().isEmpty) return;

    // A. 乐观更新：先在UI上显示消息（提升用户体验，无需等待发送成功）
    final tempMessage = ChatMessage(
      isMe: true, // 自己发送的消息
      text: event.text, // 消息内容
      avatar: 'assets/image/34.jpg', // 临时占位头像（后续可从用户信息中获取）
      sender: '我', // 发送者显示为"我"
      contentType: 0, // 0表示文本类型
    );

    // 更新状态：将临时消息添加到列表头部（最新消息在最上面），并标记"发送中"（UI显示加载动画）
    emit(state.copyWith(
      messages: [tempMessage, ...state.messages], // 新消息在前，历史消息在后
      isSending: true,
    ));

    try {
      // B. 调用API真实发送消息到后端
      await _apiService.sendMessage(
        _conversationId, // 接收者ID（当前聊天对象）
        event.text, // 消息内容
        contentType: 0, // 文本类型
        recipientId: _conversationId,
      );

      // C. 发送成功：更新状态为"发送完成"（UI停止加载动画）
      emit(state.copyWith(isSending: false));
    } catch (e) {
      // D. 发送失败：打印错误日志，更新状态（停止加载，显示错误信息）
      logger.e("文本消息发送失败: $e");
      emit(state.copyWith(
        isSending: false,
        errorMessage: "发送失败: $e", // UI可根据errorMessage显示提示
      ));
    }
  }

  /// 处理【发送图片消息事件】（ChatImageSent）
  Future<void> _onImageSent(
      ChatImageSent event, Emitter<ChatState> emit) async {
    // 1. 先更新状态为"发送中"（图片上传可能较慢，显示加载状态）
    emit(state.copyWith(isSending: true));

    try {
      // A. 调用API上传图片到存储服务（如MinIO），获取图片的唯一标识（objectKey）
      final objectKey =
          await _apiService.uploadFileAndGetObjectKey(event.image);

      // B. 乐观更新UI：先显示图片消息（用objectKey作为临时标识）
      final tempMessage = ChatMessage(
        isMe: true,
        text: objectKey, // 图片的objectKey（后续可通过它加载图片）
        avatar: 'assets/image/34.jpg',
        sender: '我',
        contentType: 1, // 1表示图片类型（与文本消息区分）
      );
      // 将图片消息添加到列表头部
      emit(state.copyWith(messages: [tempMessage, ...state.messages]));

      // C. 调用API发送图片消息（内容为objectKey，接收者可通过它下载图片）
      await _apiService.sendMessage(
        _conversationId,
        objectKey,
        contentType: 1, // 图片类型
        recipientId: _conversationId,
      );

      // 4. 发送成功：停止加载状态
      emit(state.copyWith(isSending: false));
    } catch (e) {
      // 5. 发送失败：打印日志，更新状态（停止加载，显示错误）
      logger.e("图片消息发送失败: $e");
      emit(state.copyWith(
        isSending: false,
        errorMessage: "图片发送失败",
      ));
    }
  }

  /// 处理【收到新消息事件】（ChatNewMessageReceived）
  /// 触发时机：MQTT收到消息后，通过add()触发此事件
  void _onMessageReceived(
      ChatNewMessageReceived event, Emitter<ChatState> emit) {
    // 将新收到的消息添加到列表头部（实时显示最新消息）
    emit(state.copyWith(
      messages: [event.message, ...state.messages],
    ));
  }

  /// 释放资源：当Bloc被销毁时调用（如退出聊天页面）
  @override
  Future<void> close() {
    // 取消MQTT消息订阅，防止内存泄漏（Bloc销毁后不再接收消息）
    _mqttSubscription?.cancel();
    return super.close();
  }
}
