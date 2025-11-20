// 文件: lib/models/chat_message.dart
class ChatMessage {
  final String avatar;
  final String sender;
  final String text;
  final bool isMe;
  final String level;
  final String title;
  final int contentType;

  ChatMessage({
    required this.avatar,
    required this.sender,
    required this.text,
    required this.isMe,
    this.level = '',
    this.title = '',
    this.contentType = 0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final bool isMe = json['senderId'] == currentUserId;

    return ChatMessage(
      // 暂时使用占位符，真实项目中需要根据 senderId 查询用户头像
      avatar: isMe ? 'assets/image/1.jpg' : 'assets/image/2.jpg',
      sender: json['senderId'], // 暂时直接用ID，真实项目需要查询用户名
      text: json['content'],
      isMe: isMe,
    );
  }
}
