namespace ChatProjects.Contracts.Events;

public record UserRegistered(
    string UserId,
    string UserName,
    string Email,
    string? AvatarUrl,
    DateTime Timestamp
);
