// 文件: lib/models/friend_request.dart
class FriendRequest {
  final String requestId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final DateTime sentAt;

  FriendRequest({
    required this.requestId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.sentAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatarUrl: json['senderAvatarUrl'],
      sentAt: DateTime.parse(json['sentAt']),
    );
  }
}
