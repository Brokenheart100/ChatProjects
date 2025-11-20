import 'package:equatable/equatable.dart';
import 'package:flutterchat/models/conversation.dart';

enum ConversationStatus { initial, loading, success, failure }

class ConversationState extends Equatable {
  final ConversationStatus status;
  final List<Conversation> conversations;
  final int selectedIndex; // 当前选中的会话索引
  final String? errorMessage;

  const ConversationState({
    this.status = ConversationStatus.initial,
    this.conversations = const [],
    this.selectedIndex = -1,
    this.errorMessage,
  });

  // 获取当前选中的会话对象 (方便 UI 使用)
  Conversation? get selectedConversation {
    if (selectedIndex >= 0 && selectedIndex < conversations.length) {
      return conversations[selectedIndex];
    }
    return null;
  }

  ConversationState copyWith({
    ConversationStatus? status,
    List<Conversation>? conversations,
    int? selectedIndex,
    String? errorMessage,
  }) {
    return ConversationState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, conversations, selectedIndex, errorMessage];
}
