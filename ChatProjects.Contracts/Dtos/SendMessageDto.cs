using System.ComponentModel.DataAnnotations;

namespace ChatProjects.Contracts.Dtos;

// 前端发送消息时使用的数据传输对象 (DTO)
public class SendMessageDto
{
    [Required]
    public Guid ConversationId { get; set; }

    [Required]
    public string Content { get; set; } = string.Empty;

    public int ContentType { get; set; } = 0;
}