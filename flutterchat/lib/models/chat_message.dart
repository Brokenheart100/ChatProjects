import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  @Unique(onConflict: ConflictStrategy.replace)
  String uuid;

  String conversationId;
  String senderId;
  String text;
  int contentType;
  bool isMe;
  String? avatar;

  @Property(type: PropertyType.date)
  DateTime sentAt;

  int status; // 0: sending, 1: sent, 2: failed

  // ✅ 新增：用于同步时暂存后端返回的 clientMessageId
  // 不需要加索引，因为它主要用于从 API 映射回来
  String? clientMessageId;

  ChatMessage({
    this.id = 0,
    required this.uuid,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.contentType = 0,
    required this.isMe,
    this.avatar,
    required this.sentAt,
    this.status = 1,
    this.clientMessageId, // ✅ 加入构造函数
  });

  // 用于复制对象的辅助方法 (如果你用了 Freezed，这里会自动生成，如果是手写，建议加上)
  ChatMessage copyWith({
    int? id,
    String? uuid,
    String? conversationId,
    String? senderId,
    String? text,
    int? contentType,
    bool? isMe,
    String? avatar,
    DateTime? sentAt,
    int? status,
    String? clientMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      contentType: contentType ?? this.contentType,
      isMe: isMe ?? this.isMe,
      avatar: avatar ?? this.avatar,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      clientMessageId: clientMessageId ?? this.clientMessageId,
    );
  }
}
