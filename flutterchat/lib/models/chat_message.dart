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

  ChatMessage copyWith({
    String? avatar,
    String? sender,
    String? text,
    bool? isMe,
    int? contentType,
  }) {
    return ChatMessage(
      avatar: avatar ?? this.avatar,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      contentType: contentType ?? this.contentType,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final bool isMe = json['senderId'] == currentUserId;

    return ChatMessage(
      // 暂时使用占位符，真实项目中需要根据 senderId 查询用户头像
      avatar: '',
      sender: json['senderId'], // 暂时直接用ID，真实项目需要查询用户名
      text: json['content'],
      isMe: isMe,
    );
  }
}
