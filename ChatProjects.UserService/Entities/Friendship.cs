namespace ChatProjects.UserService.Entities;

public class Friendship
{
    public Guid Id { get; set; }
    // 两个用户的 ID。为了方便查询，我们可以约定 User1Id < User2Id
    public string User1Id { get; set; } = null!;
    public string User2Id { get; set; } = null!;
    public DateTime BecameFriendsAt { get; set; }
}