import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/logger_service.dart'; // ✅ 引入 Logger

part 'group_provider.g.dart';

// 定义群成员状态
class GroupMemberState {
  final List<UserSearchResult> members;
  final bool isLoading;
  final String? error;

  GroupMemberState(
      {this.members = const [], this.isLoading = false, this.error});
}

@riverpod
class GroupManager extends _$GroupManager {
  // build 的参数 groupId 会自动成为类的字段，可以直接使用
  @override
  Future<GroupMemberState> build(String groupId) async {
    return _fetchMembers(groupId);
  }

  Future<GroupMemberState> _fetchMembers(String groupId) async {
    try {
      final api = ref.read(apiServiceProvider);
      // ✅ 修复：现在 ApiService 有这个方法了
      final members = await api.getGroupMembers(groupId);
      return GroupMemberState(members: members);
    } catch (e) {
      logger.e("获取群成员失败", error: e);
      return GroupMemberState(error: e.toString());
    }
  }

  // 踢人
  Future<void> kickMember(String userId) async {
    try {
      final api = ref.read(apiServiceProvider);

      // ✅ 修复：使用 this.groupId (来自 build 参数)
      await api.kickGroupMember(groupId: groupId, userId: userId);

      // 刷新成员列表
      ref.invalidateSelf();
    } catch (e) {
      // ✅ 修复：使用 logger
      logger.e("踢人失败", error: e);
    }
  }

  // 邀请人 (预留)
  Future<void> inviteMembers(List<String> userIds) async {
    // await api.inviteToGroup(groupId, userIds);
    ref.invalidateSelf();
  }

  // 退群
  Future<bool> leaveGroup() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.leaveGroup(groupId);
      return true;
    } catch (e) {
      logger.e("退群失败", error: e);
      return false;
    }
  }
}
