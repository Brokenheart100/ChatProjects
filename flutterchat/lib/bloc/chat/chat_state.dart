// lib/bloc/chat/chat_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutterchat/models/chat_message.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages; // 消息列表
  final bool isSending; // 是否正在发送中（用于控制发送按钮转圈）
  final String? errorMessage; // 错误信息

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  // 复制并修改状态 (Copy With 模式)
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

  @override
  List<Object?> get props => [status, messages, isSending, errorMessage];
}
