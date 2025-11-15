namespace ChatProjects.Contracts.Models
{

    public enum FriendRequestStatus
    {
        Pending,   // 0
        Accepted,  // 1
        Rejected,  // 2
        Blocked    // 3
    }
    public class FriendRequest
    {
        public Guid Id { get; set; }
        public string SenderId { get; set; } = null!;
        public string RecipientId { get; set; } = null!;
        public FriendRequestStatus Status { get; set; } // 使用我们之前定义的枚举
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; } // 添加一个更新时间字段
    }
}
