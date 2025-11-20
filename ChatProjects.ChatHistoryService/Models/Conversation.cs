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

    // 快照字段，用于列表页快速展示，避免查 Message 表
    public string? LastMessageContent { get; set; }
    public DateTime LastMessageAt { get; set; }
    public long? LastMessageId { get; set; } // 关联 Message 的雪花 ID

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}