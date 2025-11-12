// 文件: lib/models/friendship_status.dart

/// 定义好友关系的几种可能状态
enum FriendshipStatus {
  notFriend, // 非好友
  pending, // 已发送好友请求，等待对方同意
  isFriend, // 已经是好友
  blocked, // 已拉黑 (未来可能用到)
}

/// 为 FriendshipStatus 枚举添加扩展功能，使其更易于使用
extension FriendshipStatusExtension on FriendshipStatus {
  /// 将枚举转换为用户界面上显示的文本
  String get displayText {
    switch (this) {
      case FriendshipStatus.pending:
        return '已发送';
      case FriendshipStatus.isFriend:
        return '已是好友';
      // 其他状态可以根据需要添加
      default:
        return '加好友';
    }
  }

  /// 从后端返回的字符串解析成对应的枚举成员
  /// 这是一个静态辅助方法，但放在扩展里也很方便
  static FriendshipStatus fromString(String? statusString) {
    switch (statusString?.toLowerCase()) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'isfriend':
        return FriendshipStatus.isFriend;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.notFriend;
    }
  }
}
