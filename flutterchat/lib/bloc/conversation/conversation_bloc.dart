import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/mqtt_service.dart';
import 'package:uuid/uuid.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

export 'conversation_event.dart';
export 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ApiService _apiService;
  final MqttService? _mqttService;
  final String _currentUserId;
  StreamSubscription? _mqttSubscription;

  ConversationBloc({
    required ApiService apiService,
    required MqttService? mqttService,
    required String currentUserId,
  })  : _apiService = apiService,
        _mqttService = mqttService,
        _currentUserId = currentUserId,
        super(const ConversationState()) {
    on<ConversationStarted>(_onStarted);
    on<ConversationCreated>(_onCreated);
    on<ConversationUpdated>(_onUpdated);
    on<ConversationSelected>(_onSelected);

    if (_mqttService != null) {
      _mqttSubscription = _mqttService!.onMessageReceived.listen((event) {
        final isMe = event.senderId == _currentUserId;
        final msg = ChatMessage(
          isMe: isMe,
          sender: event.senderId,
          text: event.text,
          avatar: '',
        );
        // 这里的 event.conversationId 来自 MQTT 消息体
        add(ConversationUpdated(msg, event.conversationId));
      });
    }
  }

  Future<void> _onStarted(
      ConversationStarted event, Emitter<ConversationState> emit) async {
    emit(state.copyWith(status: ConversationStatus.loading));
    try {
      final conversations =
          await _apiService.getConversations(currentUserId: _currentUserId);
      emit(state.copyWith(
        status: ConversationStatus.success,
        conversations: conversations,
      ));
    } catch (e) {
      print("加载会话列表失败: $e");
      emit(state.copyWith(status: ConversationStatus.failure));
    }
  }

  void _onCreated(ConversationCreated event, Emitter<ConversationState> emit) {
    final contact = event.contact;
    // 点击联系人时，通过 recipientId 查找现有会话
    final existingIndex =
        state.conversations.indexWhere((c) => c.recipientId == contact.id);

    if (existingIndex != -1) {
      emit(state.copyWith(selectedIndex: existingIndex));
    } else {
      final newConversation = Conversation(
        id: const Uuid().v4(), // 临时 ID，等待发消息后后端返回真 ID
        recipientId: contact.id,
        name: contact.remark.isNotEmpty ? contact.remark : contact.name,
        avatar: contact.avatarUrl ?? '',
        lastMessage: '',
        time: _formatTime(DateTime.now()),
        messages: [],
      );

      final newList = List<Conversation>.from(state.conversations);
      newList.insert(0, newConversation);

      emit(state.copyWith(
        conversations: newList,
        selectedIndex: 0,
      ));
    }
  }

  // --- 核心修复逻辑 ---
  void _onUpdated(ConversationUpdated event, Emitter<ConversationState> emit) {
    final msg = event.message;
    final convId = event.conversationId; // 拿到真实的后端会话 ID

    // 1. 优先尝试通过 ID 匹配 (最准确，无论谁发的消息都能匹配上)
    int index = state.conversations.indexWhere((c) => c.id == convId);

    // 2. 如果 ID 没匹配上 (可能是新会话，或者列表还没刷新)，再尝试通过 RecipientId 匹配
    // (仅当消息是对方发的时候有效，作为兜底)
    if (index == -1 && !msg.isMe) {
      index =
          state.conversations.indexWhere((c) => c.recipientId == msg.sender);
    }

    if (index != -1) {
      final oldConv = state.conversations[index];
      final newConv = Conversation(
        id: oldConv.id,
        recipientId: oldConv.recipientId,
        name: oldConv.name,
        avatar: oldConv.avatar,
        lastMessage: msg.text,
        time: _formatTime(DateTime.now()),
        messages: oldConv.messages,
      );

      final newList = List<Conversation>.from(state.conversations);
      newList.removeAt(index);
      newList.insert(0, newConv);

      int newSelectedIndex = state.selectedIndex;
      if (index == state.selectedIndex) {
        newSelectedIndex = 0;
      } else if (index < state.selectedIndex) {
        // 保持原有选中逻辑
      } else {
        // 如果移动的是下面的项，选中项索引可能需要 +1，简单起见这里不动
      }

      emit(state.copyWith(
          conversations: newList, selectedIndex: newSelectedIndex));
    } else {
      // 如果完全找不到这个会话（说明是别人发来的新私聊，且本地列表还没刷出来）
      // 触发重新加载列表
      add(ConversationStarted());
    }
  }

  void _onSelected(
      ConversationSelected event, Emitter<ConversationState> emit) {
    emit(state.copyWith(selectedIndex: event.index));
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Future<void> close() {
    _mqttSubscription?.cancel();
    return super.close();
  }
}
