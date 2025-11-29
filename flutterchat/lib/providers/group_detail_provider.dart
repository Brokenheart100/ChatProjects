import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/providers/conversation_provider.dart';

part 'group_detail_provider.g.dart';

// 群组详情状态：目前只包含成员列表，未来可加群公告、群设置等
@riverpod
class GroupDetail extends _$GroupDetail {
  @override
  Future<List<UserSearchResult>> build(String groupId) async {
    final api = ref.read(apiServiceProvider);
    return await api.getGroupMembers(groupId);
  }

  /// 退出群聊
  Future<bool> leaveGroup() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.leaveGroup(groupId); // 这里的 groupId 来自 Family 参数

      // 退出成功后，删除本地会话列表中的条目
      ref.read(conversationListProvider.notifier).delete(groupId);
      return true;
    } catch (e) {
      print("退群失败: $e");
      return false;
    }
  }

  /// 邀请成员 (伪代码)
  Future<void> addMembers(List<String> userIds) async {
    // await api.inviteToGroup(...)
    // ref.invalidateSelf(); // 刷新列表
  }
}
