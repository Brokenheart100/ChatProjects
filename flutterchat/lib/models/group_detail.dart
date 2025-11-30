// lib/models/group_detail.dart

class GroupDetail {
  final String id;
  final String name;
  final String avatar;
  final String announcement;
  final String ownerId;
  final int memberCount;
  final int myRole; // 0:Member, 1:Admin, 2:Owner
  final List<GroupMember> members;

  GroupDetail({
    required this.id,
    required this.name,
    required this.avatar,
    required this.announcement,
    required this.ownerId,
    required this.memberCount,
    required this.myRole,
    required this.members,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '未命名群聊',
      avatar: json['avatar'] ?? '',
      announcement: json['announcement'] ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      memberCount: json['memberCount'] ?? 0,
      myRole: json['myRole'] ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GroupMember {
  final String userId;
  final String nickname;
  final String avatarUrl;
  final int role;

  GroupMember({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.role,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname'] ?? '未知用户',
      avatarUrl: json['avatarUrl'] ?? '',
      role: json['role'] ?? 0,
    );
  }
}
