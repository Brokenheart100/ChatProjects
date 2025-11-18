namespace ChatProjects.UserService.Entities
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
        public FriendRequestStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; internal set; }
    }
}
