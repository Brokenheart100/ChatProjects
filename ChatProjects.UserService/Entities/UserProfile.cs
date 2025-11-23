using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ChatProjects.UserService.Entities;

public class UserProfile
{
    [Key]
    public string UserId { get; set; } = null!;
    public string? UserName { get; set; }
    public string? Email { get; set; }
    public string?  AvatarUrl { get; set; }
    public string? DisplayName { get; set; }
    // 可以在这里添加更多字段，如 AvatarUrl, Bio, etc.
}