
namespace ChatProjects.SearchService.Models;

public class Group
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public int MemberCount { get; set; }
    public string OnlineStatus { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = [];
    public string Description { get; set; } = string.Empty;
}