namespace ChatProjects.ChatHistoryService.Dtos;
public class GroupDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;
    public string Announcement { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public int MemberCount { get; set; }

    // 当前用户在群里的角色 (0:Member, 1:Admin, 2:Owner)
    public int MyRole { get; set; }

    // 成员列表 (通常只返回前 N 个，或者全量，视群大小而定)
    public List<GroupMemberDto> Members { get; set; } = new();
}

public class GroupMemberDto
{
    public string UserId { get; set; } = string.Empty;
    public string Nickname { get; set; } = string.Empty; // 群内昵称
    public string AvatarUrl { get; set; } = string.Empty; // 冗余字段，方便前端
    public int Role { get; set; }
}
