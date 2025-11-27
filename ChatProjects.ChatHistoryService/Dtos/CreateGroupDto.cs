using System.ComponentModel.DataAnnotations;

namespace ChatProjects.ChatHistoryService.Dtos;

public class CreateGroupDto
{
    public Guid? Id { get; set; }
    [Required]
    public string GroupName { get; set; } = string.Empty;

    // 初始成员 ID 列表
    [Required]
    public List<string> MemberIds { get; set; } = new();
}