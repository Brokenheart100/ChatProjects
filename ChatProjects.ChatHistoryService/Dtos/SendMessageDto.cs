using System.ComponentModel.DataAnnotations;

namespace ChatProjects.ChatHistoryService.Dtos;


public class SendMessageDto
{
    [Required]
    public Guid ConversationId { get; set; }

    [Required]
    public string Content { get; set; } = string.Empty;

    public int ContentType { get; set; } = 0;
    public string? RecipientId { get; set; }
    public string? LocalId { get; set; }
}