// lib/bloc/conversation/conversation_bloc.dart
import 'dart:async';
// 导入flutter_bloc核心库，用于状态管理（Bloc模式）
import 'package:flutter_bloc/flutter_bloc.dart';
// 导入聊天消息模型（用于处理会话列表中的最新消息）
import 'package:flutterchat/models/chat_message.dart';
// 导入会话模型（定义会话的结构：ID、对方ID、名称、最后一条消息等）
import 'package:flutterchat/models/conversation.dart';
// 导入API服务（用于从后端获取会话列表等）
import 'package:flutterchat/services/api_service.dart';
// 导入MQTT服务（用于实时接收消息，触发会话列表更新）
import 'package:flutterchat/services/mqtt_service.dart';
// 导入uuid库（用于生成唯一会话ID）
import 'package:uuid/uuid.dart';
// 导入会话相关事件（定义触发会话列表变化的事件：初始化、创建、更新等）
import 'conversation_event.dart';
// 导入会话相关状态（定义UI需要的状态数据：会话列表、加载状态、选中项等）
import 'conversation_state.dart';

// 导出事件和状态类，方便外部（如UI层）直接导入使用
export 'conversation_event.dart';
export 'conversation_state.dart';

/// 会话列表模块的业务逻辑核心（Bloc）
/// 负责管理会话列表的加载、创建、更新（如最新消息预览）、选中状态等
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  // API服务实例（通过构造函数注入，用于与后端交互）
  final ApiService _apiService;
  // MQTT服务实例（可选，用于实时接收消息并更新会话列表）
  final MqttService? _mqttService;
  // 当前登录用户的ID（用于区分消息归属，处理会话创建/更新逻辑）
  final String _currentUserId;

  // MQTT消息订阅的流订阅对象（用于后续取消订阅，防止内存泄漏）
  StreamSubscription? _mqttSubscription;

  /// 构造函数：初始化依赖和初始状态
  /// [apiService]：后端交互服务
  /// [mqttService]：实时消息服务
  /// [currentUserId]：当前用户ID
  ConversationBloc({
    required ApiService apiService,
    required MqttService? mqttService,
    required String currentUserId,
  })  : _apiService = apiService,
        _mqttService = mqttService,
        _currentUserId = currentUserId,
        // 初始状态：空会话列表、默认状态（未加载）
        super(const ConversationState()) {
    // 注册事件与处理函数的映射
    on<ConversationStarted>(_onStarted); // 初始化事件（加载会话列表）
    on<ConversationCreated>(_onCreated); // 创建新会话事件（从联系人点击进入）
    on<ConversationUpdated>(_onUpdated); // 会话更新事件（收到新消息时）
    on<ConversationSelected>(_onSelected); // 会话选中事件（切换聊天对象）

    // --- 核心逻辑：监听全局MQTT消息，实时更新会话列表预览 ---
    if (_mqttService != null) {
      // 订阅MQTT的消息接收流，任何新消息都会触发回调
      _mqttSubscription = _mqttService!.onMessageReceived.listen((event) {
        // 将MQTT事件转换为通用的ChatMessage模型（用于更新会话列表的最后一条消息）
        final isMe = event.senderId == _currentUserId; // 是否自己发送的消息
        final msg = ChatMessage(
          isMe: isMe,
          sender: event.senderId, // 发送者ID（对方或自己）
          text: event.text, // 消息内容（用于会话列表预览）
          avatar: '', // 会话列表预览不需要每条消息的具体头像
        );

        // 触发会话更新事件：通知Bloc有新消息，需要更新对应会话的预览信息
        add(ConversationUpdated(msg));
      });
    }
  }

  /// 处理【会话初始化事件】（ConversationStarted）
  /// 触发时机：进入会话列表页面时，加载最近的会话列表
  Future<void> _onStarted(
      ConversationStarted event, Emitter<ConversationState> emit) async {
    // 1. 更新状态为"加载中"（UI显示加载动画）
    emit(state.copyWith(status: ConversationStatus.loading));
    try {
      // TODO: 实际项目中需调用API获取真实会话列表
      // final conversations = await _apiService.getRecentConversations();
      // 这里暂时返回空列表（或保留模拟数据）
      emit(state.copyWith(
        status: ConversationStatus.success,
        conversations: [], // 后续替换为真实API返回的会话列表
      ));
    } catch (e) {
      // 加载失败：更新状态为"失败"（UI可显示错误提示）
      emit(state.copyWith(status: ConversationStatus.failure));
    }
  }

  /// 处理【创建新会话事件】（ConversationCreated）
  /// 触发时机：从联系人列表点击某个联系人时，创建与该联系人的会话
  void _onCreated(ConversationCreated event, Emitter<ConversationState> emit) {
    final contact = event.contact; // 选中的联系人信息

    // 检查该联系人的会话是否已存在（避免重复创建）
    final existingIndex =
        state.conversations.indexWhere((c) => c.recipientId == contact.id);

    if (existingIndex != -1) {
      // 会话已存在：直接选中该会话（UI切换到对应的聊天页面）
      emit(state.copyWith(selectedIndex: existingIndex));
    } else {
      // 会话不存在：创建新会话并插入到列表顶部（最新会话在最前面）
      final newConversation = Conversation(
        id: const Uuid().v4(), // 生成唯一会话ID（也可使用联系人ID作为会话ID）
        recipientId: contact.id, // 对方的用户ID
        name: contact.remark.isNotEmpty
            ? contact.remark
            : contact.name, // 显示备注名（无则显示原名）
        avatar: contact.avatarUrl ?? '', // 对方的头像URL
        lastMessage: '', // 初始无消息
        time: _formatTime(DateTime.now()), // 会话创建时间
        messages: [], // 初始无消息（实际消息由ChatBloc管理）
      );

      // 复制现有列表，将新会话插入到顶部
      final newList = List<Conversation>.from(state.conversations);
      newList.insert(0, newConversation);

      // 更新状态：新会话列表 + 选中刚创建的会话（索引为0）
      emit(state.copyWith(
        conversations: newList,
        selectedIndex: 0,
      ));
    }
  }

  /// 处理【会话更新事件】（ConversationUpdated）
  /// 触发时机：收到新消息时（通过MQTT），更新对应会话的最后一条消息、时间，并置顶
  void _onUpdated(ConversationUpdated event, Emitter<ConversationState> emit) {
    final msg = event.message; // 新收到的消息

    // 确定目标会话的对方ID：
    // - 若消息是别人发的，对方ID是消息发送者ID
    // - 若消息是自己发的（多端同步），对方ID是会话的接收者（需根据实际协议调整）
    final targetId = msg.isMe ? msg.sender : msg.sender; // 简化逻辑，需根据实际MQTT协议微调

    // 查找目标会话在列表中的索引
    final index = state.conversations.indexWhere(
      (c) => c.recipientId == targetId || c.recipientId == _currentUserId,
    );

    if (index != -1) {
      // 找到目标会话：更新其最后一条消息、时间，并置顶
      final oldConv = state.conversations[index];
      final newConv = Conversation(
        id: oldConv.id,
        recipientId: oldConv.recipientId,
        name: oldConv.name,
        avatar: oldConv.avatar,
        lastMessage: msg.text, // 更新最后一条消息（用于列表预览）
        time: _formatTime(DateTime.now()), // 更新消息时间
        messages: oldConv.messages, // 历史消息引用不变（由ChatBloc单独管理）
      );

      // 复制现有列表，移除旧会话，将更新后的会话插入到顶部（置顶）
      final newList = List<Conversation>.from(state.conversations);
      newList.removeAt(index);
      newList.insert(0, newConv);

      // 修正选中索引：避免因置顶导致选中状态错乱
      int newSelectedIndex = state.selectedIndex;
      if (index == state.selectedIndex) {
        // 若之前选中的是当前会话，置顶后索引变为0
        newSelectedIndex = 0;
      } else if (index < state.selectedIndex) {
        // 若之前选中的会话在当前会话下方，当前会话移除后，选中索引减1
        newSelectedIndex = state.selectedIndex - 1;
      } else {
        // 其他情况：通过会话ID重新匹配选中项（确保选中状态正确）
        newSelectedIndex =
            newList.indexWhere((c) => c.id == state.selectedConversation?.id);
      }

      // 更新状态：新会话列表 + 修正后的选中索引
      emit(state.copyWith(
        conversations: newList,
        selectedIndex: newSelectedIndex,
      ));
    }
  }

  /// 处理【会话选中事件】（ConversationSelected）
  /// 触发时机：点击会话列表中的某个会话时，更新选中索引（UI切换到对应的聊天页面）
  void _onSelected(
      ConversationSelected event, Emitter<ConversationState> emit) {
    emit(state.copyWith(selectedIndex: event.index));
  }

  /// 辅助方法：格式化时间为 "HH:MM" 格式（用于会话列表的时间显示）
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// 释放资源：当Bloc被销毁时调用（如退出会话列表页面）
  @override
  Future<void> close() {
    // 取消MQTT订阅，防止Bloc销毁后仍接收消息导致内存泄漏
    _mqttSubscription?.cancel();
    return super.close();
  }
}
