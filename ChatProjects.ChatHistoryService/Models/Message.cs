using System.ComponentModel.DataAnnotations.Schema;

namespace ChatProjects.ChatHistoryService.Models;
public class Message
{
    [DatabaseGenerated(DatabaseGeneratedOption.None)] // 告诉EF Core我们自己提供ID
    public long Id { get; set; }
    public Guid ConversationId { get; set; }
    public string SenderId { get; set; } = null!;
    public string Content { get; set; } = null!;
    public int ContentType { get; set; }
    public DateTime SentAt { get; set; }
}