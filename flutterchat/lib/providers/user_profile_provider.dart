import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_entity.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';

part 'user_profile_provider.g.dart';

@riverpod
Future<UserEntity> userProfile(UserProfileRef ref, String userId) async {
  // 1. 尝试读缓存
  try {
    final db = ref.watch(objectBoxProvider);
    final localUser = db.getUser(userId);
    if (localUser != null) return localUser;
  } catch (e) {
    // 忽略缓存读取错误
  }

  // 2. 网络请求
  try {
    final api = ref.read(apiServiceProvider);
    final users = await api.getUsersBatch([userId]);

    if (users.isNotEmpty) {
      final u = users.first;

      // 🔍 运行时防御：确保 ID 不为空
      final safeId = (u.userId.isEmpty) ? userId : u.userId;
      final safeName = (u.username.isEmpty) ? "未知用户" : u.username;
      // 即使编译器说 avatarUrl 不会是 null，我们通过 api 方法转换后确保它是 String
      final safeAvatar = api.getFullAvatarUrl(u.avatarUrl) ?? "";

      final entity = UserEntity(
        userId: safeId,
        username: safeName,
        avatarUrl: safeAvatar,
        updatedAt: DateTime.now(),
      );

      // 3. 写入缓存
      try {
        final db = ref.read(objectBoxProvider);
        db.saveUser(entity);
      } catch (_) {}

      return entity;
    } else {
      logger.w("⚠️ [UserProfile] API 查无此人: $userId");
    }
  } catch (e) {
    logger.e("❌ [UserProfile] API 请求失败", error: e);
  }

  // 4. 最终兜底 (UI 显示未知用户，而不是红屏)
  return UserEntity(
    userId: userId,
    username: "未知用户",
    avatarUrl: "",
    updatedAt: DateTime.now(),
  );
}
