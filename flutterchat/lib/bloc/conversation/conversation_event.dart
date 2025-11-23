import 'package:equatable/equatable.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/contact.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class ConversationStarted extends ConversationEvent {}

class ConversationCreated extends ConversationEvent {
  final Contact contact;
  const ConversationCreated(this.contact);
}

// --- 核心修改：增加 conversationId 字段 ---
class ConversationUpdated extends ConversationEvent {
  final ChatMessage message;
  final String conversationId; // <--- 新增

  const ConversationUpdated(this.message, this.conversationId);

  @override
  List<Object?> get props => [message, conversationId];
}
// ----------------------------------------

class ConversationSelected extends ConversationEvent {
  final int index;
  const ConversationSelected(this.index);
}
