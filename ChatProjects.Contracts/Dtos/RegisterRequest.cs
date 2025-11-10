namespace ChatProjects.Contracts.Dtos
{
    // 在 AuthService 项目或 Shared 项目中
    public class RegisterRequest
    {
        public required string Username { get; set; }
        public required string Email { get; set; }
        public required string Password { get; set; }

        // 新增：头像的 Object Key，这个字段是可选的
        public string? AvatarObjectKey { get; set; }
    }
}
