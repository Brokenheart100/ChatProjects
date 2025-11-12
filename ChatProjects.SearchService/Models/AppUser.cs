// 文件: ChatProjects.SearchService/Models/AppUser.cs
using System.ComponentModel.DataAnnotations.Schema;
namespace ChatProjects.SearchService.Models;

[Table("AspNetUsers")]
public class AppUser
{
    public string Id { get; set; } = null!;
    public string? UserName { get; set; }
    public string? Email { get; set; }
    public string? AvatarUrl { get; set; }
}