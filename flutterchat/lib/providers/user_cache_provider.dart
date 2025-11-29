import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_entity.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart'; // ✅ 引入 Logger

part 'user_cache_provider.g.dart';

@Riverpod(keepAlive: true)
class UserCache extends _$UserCache {
  @override
  void build() {
    return;
  }

  UserEntity? getUser(String userId) {
    final db = ref.read(objectBoxProvider);
    return db.getUser(userId);
  }

  Future<void> syncUsers(List<String> userIds) async {
    final db = ref.read(objectBoxProvider);
    final api = ref.read(apiServiceProvider);

    // 1. 过滤出本地没有的用户
    final missingIds =
        userIds.where((id) => db.getUser(id) == null).toSet().toList();

    if (missingIds.isEmpty) return;

    logger.i("🔄 [UserCache] 发现 ${missingIds.length} 个未知用户，开始批量同步...");

    try {
      // 2. 调用 API (现在 ApiService 里已经有这个方法了)
      final remoteUsers = await api.getUsersBatch(missingIds);

      // 3. 转换为本地实体并存储
      final entities = remoteUsers.map((u) {
        // 🔍 调试：看看哪个是 null
        if (u.avatarUrl == null) {
          logger.i("✅ [UserCache] u.avatarUrl ${u.avatarUrl} ");
        }
        if (u.userId.isEmpty) {
          logger.e("❌ [UserCache] 遇到无效用户数据: $u");
          return null; // 标记为脏数据
        }
        return UserEntity(
          userId: u.userId,
          username: u.username,
          avatarUrl: api.getFullAvatarUrl(u.avatarUrl),
          updatedAt: DateTime.now(),
        );
      }).toList();

      db.saveUsers(entities.cast<UserEntity>());

      logger.i("✅ [UserCache] 成功缓存 ${entities.length} 个用户信息");
    } catch (e) {
      // ✅ 修复：使用 logger 记录错误
      logger.e("❌ [UserCache] 同步用户信息失败", error: e);
    }
  }
}
