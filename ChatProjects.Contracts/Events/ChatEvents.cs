namespace ChatProjects.Contracts.Events;

// --- 下面是本次补充的三个事件 ---

public record GroupNameUpdated(Guid GroupId, string NewName);

public record GroupMemberKicked(Guid GroupId, string UserId);

public record GroupMemberLeft(Guid GroupId, string UserId);