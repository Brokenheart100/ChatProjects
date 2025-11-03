using System.ComponentModel.DataAnnotations;

namespace ChatProjects.AuthService.Dtos;

// 用于用户注册的 DTO
public record RegisterDto(
    [Required]
    [EmailAddress]
    string Email,

    [Required]
    string Username,

    [Required]
    string Password
);

// 用于用户登录的 DTO
public record LoginDto(
    [Required]
    string Username,

    [Required]
    string Password
);

// 认证成功后返回给客户端的 DTO
public record AuthResponseDto(
    string UserId,
    string Username,
    string Email,
    string Token
);