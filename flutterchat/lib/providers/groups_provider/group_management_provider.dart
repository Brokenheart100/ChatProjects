import 'package:flutterchat/models/group_detail.dart';
import 'package:flutterchat/objectbox.g.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_management_provider.g.dart';

// 这是一个 Family Provider，根据 groupId 自动区分状态
// 它的状态类型是 GroupDetail (包含成员列表、群名等)
@riverpod
class GroupManagement extends _$GroupManagement {
  @override
  Future<GroupDetail> build(String groupId) async {
    final api = ref.read(apiServiceProvider);
    // 初始化时拉取最新详情
    return await api.getGroupDetail(groupId);
  }

  /// 修改群名
  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;

    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(objectBoxProvider);

      // 1. 调 API
      await api.updateGroupName(groupId, newName);

      // 2. 更新本地会话 (让聊天列表瞬间刷新)
      final box = db.conversationBox;
      final query = box.query(Conversation_.uuid.equals(groupId)).build();
      final conv = query.findFirst();
      query.close();

      if (conv != null) {
        // 注意：ObjectBox 中修改对象需要重新 put
        // 为了避免引用问题，建议创建一个副本或者直接修改属性后 put
        // 这里直接修改属性
        conv.name = newName;
        box.put(conv);
        logger.i("✅ [GroupManagement] 群名已本地更新: $newName");
      }

      // 3. 刷新当前页面数据 (重新拉取 GroupDetail)
      ref.invalidateSelf();
    } catch (e) {
      logger.e("修改群名失败", error: e);
      rethrow;
    }
  }

  /// 退出群聊
  Future<bool> leaveGroup() async {
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(objectBoxProvider);

      // 1. 调 API
      await api.leaveGroup(groupId);

      // 2. 删本地
      final box = db.conversationBox;
      final query = box.query(Conversation_.uuid.equals(groupId)).build();
      final conv = query.findFirst();
      query.close();

      if (conv != null) {
        box.remove(conv.id);
      }

      logger.i("✅ [GroupManagement] 退群成功");
      return true;
    } catch (e) {
      logger.e("退群失败", error: e);
      return false;
    }
  }

  /// 踢出成员 (合并进来的功能)
  Future<void> kickMember(String memberId) async {
    try {
      final api = ref.read(apiServiceProvider);

      // 1. 调 API
      await api.kickGroupMember(groupId: groupId, userId: memberId);

      // 2. 成功后，刷新当前 Provider，UI 会自动重新拉取最新的成员列表
      ref.invalidateSelf();

      logger.i("✅ [GroupManagement] 已踢出成员: $memberId");
    } catch (e) {
      logger.e("踢人失败", error: e);
      // 可以选择 rethrow 让 UI 处理报错弹窗
    }
  }
}
