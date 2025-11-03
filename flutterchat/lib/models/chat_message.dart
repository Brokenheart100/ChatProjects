class ChatMessage {
  final String avatar;
  final String sender;
  final String text;
  final bool isMe;
  final String level;
  final String title;

  ChatMessage({
    required this.avatar,
    required this.sender,
    required this.text,
    required this.isMe,
    this.level = '',
    this.title = '',
  });
}
