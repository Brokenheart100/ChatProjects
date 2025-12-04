import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  @Id()
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String uuid;

  @Index()
  String conversationId;

  String senderId;
  String text;
  bool isMe;
  int contentType;
  String avatar;

  @Property(type: PropertyType.date)
  DateTime sentAt;

  int status;

  ChatMessage({
    this.id = 0,
    required this.uuid,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.isMe,
    this.contentType = 0,
    required this.avatar,
    required this.sentAt,
    this.status = 1,
  });

  // ✅ 核心修复：确保这里包含了 conversationId
  ChatMessage copyWith({
    int? id,
    String? uuid,
    String? conversationId, // <--- 之前可能缺了这个
    String? senderId,
    String? text,
    bool? isMe,
    int? contentType,
    String? avatar,
    DateTime? sentAt,
    int? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      contentType: contentType ?? this.contentType,
      avatar: avatar ?? this.avatar,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final senderId = json['senderId'].toString();
    return ChatMessage(
      id: 0,
      uuid: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      text: json['content'] ?? '',
      contentType: json['contentType'] ?? 0,
      isMe: senderId.toLowerCase() == currentUserId.toLowerCase(),
      avatar: '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      status: 1,
    );
  }
}
