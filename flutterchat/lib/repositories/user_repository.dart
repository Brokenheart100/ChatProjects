import 'package:flutterchat/models/user_entity.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:flutterchat/services/objectbox_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(
    api: ref.watch(apiServiceProvider),
    db: ref.watch(objectBoxProvider),
  );
}

class UserRepository {
  final ApiService _api;
  final ObjectBoxService _db;

  UserRepository({required ApiService api, required ObjectBoxService db})
      : _api = api,
        _db = db;

  /// 获取用户信息 (优先读缓存，无缓存则读网络并缓存)
  Future<UserEntity> getUser(String userId) async {
    // 1. 查缓存
    final localUser = _db.getUser(userId);
    if (localUser != null) {
      // 可选：后台静默刷新 (Stale-While-Revalidate)
      _fetchAndSave(userId).ignore();
      return localUser;
    }

    // 2. 查网络并缓存
    return await _fetchAndSave(userId);
  }

  /// 批量同步用户 (用于会话列表加载时)
  Future<void> syncBatch(List<String> userIds) async {
    // 过滤掉本地已有的，或者强制全部刷新
    final missingIds = userIds.where((id) => _db.getUser(id) == null).toList();
    if (missingIds.isEmpty) return;

    try {
      final remoteUsers = await _api.getUsersBatch(missingIds);
      final entities = remoteUsers.map((u) => _mapToEntity(u)).toList();
      _db.saveUsers(entities);
    } catch (e) {
      logger.e("批量同步用户失败", error: e);
    }
  }

  /// 私有辅助：拉取并保存
  Future<UserEntity> _fetchAndSave(String userId) async {
    final remoteUser = await _api.getUserProfile(userId); // 假设 API 有此方法
    final entity = _mapToEntity(remoteUser);
    _db.saveUser(entity);
    return entity;
  }

  // Model 转换逻辑
  UserEntity _mapToEntity(UserSearchResult remote) {
    return UserEntity(
      userId: remote.userId,
      username: remote.username,
      avatarUrl: _api.getFullAvatarUrl(remote.avatarUrl),
      updatedAt: DateTime.now(),
    );
  }
}
