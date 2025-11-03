import 'chat_message.dart'; // 引入ChatMessage模型

class Conversation {
  final String avatar;
  final String name;
  final String lastMessage;
  final String time;
  final bool isMuted;
  final List<ChatMessage> messages; // <-- 新增字段：存储该会话的所有消息

  Conversation({
    required this.avatar,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.messages, // <-- 在构造函数中要求传入消息列表
    this.isMuted = false,
  });
}
