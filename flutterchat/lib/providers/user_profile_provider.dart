import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_entity.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';

part 'user_profile_provider.g.dart';

@riverpod
Future<UserEntity> userProfile(UserProfileRef ref, String userId) async {
  // final db = ref.watch(objectBoxProvider);

  // 1. 先读本地缓存
  // final localUser = db.getUser(userId);
  // if (localUser != null) {
  //   return localUser;
  // }

  // 2. 本地没有，读网络
  final api = ref.read(apiServiceProvider);
  try {
    // 使用 batch 接口查询
    final users = await api.getUsersBatch([userId]);

    // ✅ 核心修复：严格检查是否为空
    if (users.isNotEmpty) {
      final u = users[0];
      final entity = UserEntity(
        userId: u.userId,
        username: u.username,
        avatarUrl: api.getFullAvatarUrl(u.avatarUrl),
        updatedAt: DateTime.now(),
      );

      // 存入本地
      // db.saveUser(entity);
      return entity;
    } else {
      // ⚠️ 查不到用户 (脏数据 ID)，打印警告
      logger.w("⚠️ [UserProfile] 后端查无此人: $userId");
    }
  } catch (e) {
    logger.e("❌ [UserProfile] API 请求失败", error: e);
  }

  // 3. 兜底策略：无论上面发生什么错误，都返回一个占位对象
  // 这样 UI 永远不会崩，只会显示 "未知用户"
  return UserEntity(
      userId: userId,
      username: "API请求失败",
      avatarUrl: "",
      updatedAt: DateTime.now());
}
