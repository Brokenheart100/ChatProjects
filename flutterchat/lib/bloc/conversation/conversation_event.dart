import 'package:equatable/equatable.dart';
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/contact.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

// 1. 初始化：从服务器拉取最近的会话列表
class ConversationStarted extends ConversationEvent {}

// 2. 收到消息更新：(无论是自己发的，还是MQTT收到的，都通过这个更新列表预览)
class ConversationUpdated extends ConversationEvent {
  final ChatMessage message; // 使用 ChatMessage 模型方便统一处理
  const ConversationUpdated(this.message);
}

// 3. 手动开启会话：在联系人列表点击某人，需要在会话列表创建一个项
class ConversationCreated extends ConversationEvent {
  final Contact contact;
  const ConversationCreated(this.contact);
}

// 4. 选中会话 (用于标记已读等逻辑，暂时只做UI选中)
class ConversationSelected extends ConversationEvent {
  final int index;
  const ConversationSelected(this.index);
}
