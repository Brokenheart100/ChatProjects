import 'package:objectbox/objectbox.dart';

@Entity()
class UserEntity {
  @Id()
  int id = 0;

  @Unique(onConflict: ConflictStrategy.replace)
  String userId; // 业务主键

  String username;
  String avatarUrl;

  @Property(type: PropertyType.date)
  DateTime updatedAt; // 用于将来做缓存过期策略

  UserEntity({
    this.id = 0,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.updatedAt,
  });
}
