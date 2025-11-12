import 'package:flutterchat/models/friendship_status.dart';

class UserSearchResult {
  final String userId;
  final String username;
  final String? avatarUrl;
  FriendshipStatus friendshipStatus;

  UserSearchResult({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.friendshipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
        userId: json['userId'],
        username: json['username'],
        avatarUrl: json['avatarUrl'],
        friendshipStatus:
            FriendshipStatusExtension.fromString(json['friendshipStatus']));
  }
}
