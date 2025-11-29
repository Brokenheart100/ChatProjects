namespace ChatProjects.Contracts.Events;

// 建群事件：告诉 RealtimeService 谁被拉进群了
public record GroupCreatedEvent(
    Guid GroupId,
    string GroupName,
    string CreatorId,
    List<string> MemberIds, // 包含所有成员 ID
    DateTime CreatedAt
);