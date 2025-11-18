using System.ComponentModel.DataAnnotations.Schema;

namespace ChatProjects.UserService.Entities;

// 将这个类映射到 Identity 框架创建的 "AspNetUsers" 表
[Table("AspNetUsers")]
public class UserProfile
{
    public string UserId { get; set; } = null!;
    public string? UserName { get; set; }
    public string? Email { get; set; }
    public string?  AvatarUrl { get; set; }
    public string? DisplayName { get; set; }
    // 可以在这里添加更多字段，如 AvatarUrl, Bio, etc.
}