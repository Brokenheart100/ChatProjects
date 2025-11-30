import 'package:dio/dio.dart';
import 'package:flutterchat/models/group_detail.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api/api_base.dart';
import 'package:flutterchat/services/logger_service.dart';

mixin GroupApi on ApiBase {
  /// 创建群聊
  /// [id]: 前端生成的 UUID
  Future<void> createGroup(
      String id, String groupName, List<String> memberIds) async {
    try {
      await dio.post('/gateway/groups', data: {
        'id': id,
        'groupName': groupName,
        'memberIds': memberIds,
      });
      logger.i("✅ API调用成功: 群聊已创建 (ID: $id)");
    } on DioException catch (e) {
      throw handleError(e, 'createGroup');
    }
  }

  /// 获取群组详情 (包含成员列表、我的角色等)
  Future<GroupDetail> getGroupDetail(String groupId) async {
    try {
      final response = await dio.get('/gateway/groups/$groupId');
      return GroupDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw handleError(e, 'getGroupDetail');
    }
  }

  /// 获取群成员列表
  Future<List<UserSearchResult>> getGroupMembers(String groupId) async {
    try {
      final response = await dio.get('/gateway/groups/$groupId/members');
      return (response.data as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw handleError(e, 'getGroupMembers');
    }
  }

  /// 修改群名称
  Future<void> updateGroupName(String groupId, String newName) async {
    try {
      // 假设后端接口是 PUT /gateway/groups/{id}/name
      await dio.put('/gateway/groups/$groupId/name', data: {'name': newName});
    } on DioException catch (e) {
      throw handleError(e, 'updateGroupName');
    }
  }

  /// 踢出群成员
  Future<void> kickGroupMember(
      {required String groupId, required String userId}) async {
    try {
      await dio.post('/gateway/groups/$groupId/kick', data: {'userId': userId});
    } on DioException catch (e) {
      throw handleError(e, 'kickGroupMember');
    }
  }

  /// 退出群聊
  Future<void> leaveGroup(String groupId) async {
    try {
      await dio.post('/gateway/groups/$groupId/leave');
    } on DioException catch (e) {
      throw handleError(e, 'leaveGroup');
    }
  }
}
