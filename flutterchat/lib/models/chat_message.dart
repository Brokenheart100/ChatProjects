import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  // ObjectBox 内部主键 (本地自增)
  @Id()
  int id;

  // 业务主键 (后端的 UUID)，加唯一索引，用于去重
  @Unique(onConflict: ConflictStrategy.replace)
  String uuid;

  @Index()
  String conversationId;

  String senderId;
  String text;
  bool isMe;
  int contentType;
  String avatar;

  @Property(type: PropertyType.date) // 显式声明日期存储
  DateTime sentAt;

  // 0=发送中, 1=成功, 2=失败
  int status;

  ChatMessage({
    this.id = 0, // 默认 0 表示新插入
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

  // 用于 ObjectBox 更新时的复制方法
  ChatMessage copyWith({
    int? id, // 本地 ID 必须保留
    String? uuid,
    int? status,
    String? avatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      isMe: isMe,
      contentType: contentType,
      avatar: avatar ?? this.avatar,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }

  // 保持 API 兼容性
  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final senderId = json['senderId'].toString();
    return ChatMessage(
      id: 0, // 总是 0，插入时由 ObjectBox 决定
      uuid: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      text: json['content'] ?? '',
      contentType: json['contentType'] ?? 0,
      isMe: senderId == currentUserId,
      avatar: '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      status: 1,
    );
  }
}
