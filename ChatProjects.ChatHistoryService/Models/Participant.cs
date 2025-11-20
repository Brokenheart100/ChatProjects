using Microsoft.EntityFrameworkCore;

namespace ChatProjects.ChatHistoryService.Models;


[PrimaryKey(nameof(ConversationId), nameof(UserId))]
public class Participant
{
    public Guid ConversationId { get; set; }
    public string UserId { get; set; } = string.Empty;
    // 企业级特性：消息免打扰
    public bool IsMuted { get; set; } = false;

    // 企业级特性：置顶
    public bool IsPinned { get; set; } = false;

    // 企业级特性：已读回执/未读计数
    // 记录该用户在这个会话中看到的最后一条消息 ID (雪花ID)
    public long LastReadMessageId { get; set; }
}