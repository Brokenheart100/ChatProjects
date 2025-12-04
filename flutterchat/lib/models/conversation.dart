import 'package:objectbox/objectbox.dart';

@Entity()
class Conversation {
  @Id()
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String uuid;

  String recipientId;
  String name;
  String avatar;
  String lastMessage;

  @Property(type: PropertyType.date)
  DateTime lastMessageAt;

  bool isGroup;
  int unreadCount;

  Conversation({
    this.id = 0,
    required this.uuid,
    required this.recipientId,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.isGroup = false,
    this.unreadCount = 0,
  });
}
