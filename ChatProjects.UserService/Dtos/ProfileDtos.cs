// UserService/Dtos/ProfileDtos.cs

using System.ComponentModel.DataAnnotations;

namespace ChatProjects.UserService.Dtos;

// 用于显示用户个人资料的 DTO
public record UserProfileDto(
    string Id,
    string Username,
    string Email,
    string? DisplayName
);

// 用于更新用户个人资料的 DTO
public record UpdateProfileDto(
    [Required]
    [StringLength(50, MinimumLength = 2)]
    string DisplayName
);