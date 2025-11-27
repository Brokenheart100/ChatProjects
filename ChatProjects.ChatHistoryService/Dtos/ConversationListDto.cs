namespace ChatProjects.ChatHistoryService.Dtos;
public class ConversationListDto
{
    public Guid Id { get; set; }
    public string RecipientId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty; // 聚合后的名字
    public string Avatar { get; set; } = string.Empty; // 聚合后的头像
    public string LastMessage { get; set; } = string.Empty;
    public DateTime LastMessageAt { get; set; }
    public int Type { get; set; }
}

