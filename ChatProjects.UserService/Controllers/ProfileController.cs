// UserService/Controllers/ProfileController.cs

using System.Security.Claims;
using ChatProjects.UserService.Data;
using ChatProjects.UserService.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChatProjects.UserService.Controllers;

[ApiController]
[Route("api/[controller]")] // 路由: /api/profile
[Authorize] // **重要：标记整个控制器都需要身份验证**
public class ProfileController : ControllerBase
{
    private readonly UserDbContext _context;

    public ProfileController(UserDbContext context)
    {
        _context = context;
    }

    // GET /api/profile/me
    // 获取当前登录用户的个人资料
    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        // 从 JWT 令牌的声明(claims)中获取用户 ID
        // 这是微服务中识别当前用户的标准做法
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (userId == null)
        {
            return Unauthorized(); // 如果令牌中没有用户 ID，则拒绝访问
        }

        var user = await _context.Users.FindAsync(userId);

        if (user == null)
        {
            return NotFound("未找到用户");
        }

        var profileDto = new UserProfileDto(user.Id, user.UserName!, user.Email!, user.DisplayName);
        return Ok(profileDto);
    }

    // PUT /api/profile/me
    // 更新当前登录用户的个人资料
    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileDto updateDto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null)
        {
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound("未找到用户");
        }

        // 更新字段
        user.DisplayName = updateDto.DisplayName;

        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        return NoContent(); // 204 No Content 是更新成功的标准响应
    }

    // GET /api/profile/{id}
    // 获取指定ID用户的公开信息 (此端点也可以设置为公开访问)
    [HttpGet("{id}")]
    public async Task<IActionResult> GetUserProfileById(string id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound();
        }

        // 通常只返回公开信息，而不是所有信息
        var publicProfile = new UserProfileDto(user.Id, user.UserName!, user.Email!, user.DisplayName);
        return Ok(publicProfile);
    }
}