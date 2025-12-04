namespace ChatProjects.Contracts.Events;

public record UserStatusChangedEvent(
    string UserId,          // 谁的状态变了
    string Status,          // "online" 或 "offline"
    List<string> FriendIds  // 通知谁 (他的好友列表)
);