using Microsoft.EntityFrameworkCore;

namespace ChatProjects.ChatHistoryService.Models;


[PrimaryKey(nameof(ConversationId), nameof(UserId))]
public class Participant
{
    public Guid ConversationId { get; set; }
    public string UserId { get; set; } = string.Empty;
}