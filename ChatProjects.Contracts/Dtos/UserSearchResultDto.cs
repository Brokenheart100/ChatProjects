namespace ChatProjects.Contracts.Dtos
{
    public record UserSearchResultDto(
        string UserId,
        string Username,
        string? AvatarUrl,
        // 可以添加一个字段表示你们是否已经是好友
        string FriendshipStatus
    );
}
