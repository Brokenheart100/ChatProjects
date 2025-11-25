using System.ComponentModel.DataAnnotations;

namespace ChatProjects.ChatHistoryService.Models;

public enum ConversationType
{
    Private = 0,
    Group = 1
}

public class Conversation
{
    [Key]
    public Guid Id { get; set; }

    public ConversationType Type { get; set; }

    public string? Name { get; set; }
    public string? Avatar { get; set; }
    public string? LastMessageContent { get; set; }
    public DateTime LastMessageAt { get; set; }
    public long? LastMessageId { get; set; } // 关联 Message 的雪花 ID

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<Participant> Participants { get; set; } = new List<Participant>();
}