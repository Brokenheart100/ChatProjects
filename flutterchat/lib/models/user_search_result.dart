import 'package:flutterchat/models/friendship_status.dart';

class UserSearchResult {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  FriendshipStatus friendshipStatus;

  UserSearchResult({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    required this.friendshipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      // ✅ 核心修复：多重兜底，防止 ID 为 null
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',

      // ✅ 核心修复：多重兜底，防止名字为 null
      username:
          json['username']?.toString() ?? json['name']?.toString() ?? '未知用户',

      // 头像允许为 null
      avatarUrl: json['avatarUrl']?.toString(),

      // 状态防御
      friendshipStatus: json['friendshipStatus'] != null
          ? FriendshipStatusExtension.fromString(
              json['friendshipStatus'].toString())
          : FriendshipStatus.notFriend,
      isOnline: json['isOnline'] ?? false,
    );
  }
}
