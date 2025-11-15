namespace ChatProjects.Contracts.Models
{
    // 文件: ChatProjects.UserService/Entities/Friendship.cs
    public class Friendship
    {
        public Guid Id { get; set; }
        // 约定 User1Id 的字符串值 < User2Id 的字符串值，方便查询
        public string User1Id { get; set; } = null!;
        public string User2Id { get; set; } = null!;
        public DateTime BecameFriendsAt { get; set; }
    }
}
