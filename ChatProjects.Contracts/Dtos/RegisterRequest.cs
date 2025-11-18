namespace ChatProjects.Contracts.Dtos
{
    public record FriendRequestDto(
        Guid RequestId,
        string SenderId,
        string SenderName,
        string? SenderAvatarUrl,
        DateTime SentAt
    );
}
