using ChatProjects.AuthService.Dtos;
using ChatProjects.AuthService.Models;
using ChatProjects.AuthService.Services;
using ChatProjects.Contracts.Events;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Wolverine;

namespace ChatProjects.AuthService.Controllers;

[ApiController] // 标记这是一个 API 控制器，会自动启用模型验证等功能
[Route("api/[controller]")] // 定义路由模板，这里会自动解析为 "api/auth"
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly TokenService _tokenService;
    private readonly IMessageBus _messageBus;

    // 通过构造函数注入所有需要的服务
    public AuthController(UserManager<AppUser> userManager, TokenService tokenService, IMessageBus messageBus)
    {
        _userManager = userManager;
        _tokenService = tokenService;
        _messageBus = messageBus;
    }

    // POST api/auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto registerDto)
    {
        var userExists = await _userManager.FindByNameAsync(registerDto.Username);
        if (userExists != null)
        {
            // 返回 409 Conflict 状态码，表示资源冲突
            return Conflict("用户名已存在");
        }

        var emailExists = await _userManager.FindByEmailAsync(registerDto.Email);
        if (emailExists != null)
        {
            return Conflict("邮箱已被注册");
        }

        var newUser = new AppUser
        {
            Email = registerDto.Email,
            UserName = registerDto.Username,
            SecurityStamp = Guid.NewGuid().ToString(),
            AvatarUrl = registerDto.AvatarUrl
        };

        var result = await _userManager.CreateAsync(newUser, registerDto.Password);

        if (!result.Succeeded)
        {
            // 返回 400 Bad Request，并附带 Identity 框架生成的具体错误信息
            return BadRequest(result.Errors);
        }
        // --- 4. 核心新增：发布 UserRegistered 事件 ---
        var userRegisteredEvent = new UserRegistered(
            newUser.Id,
            newUser.UserName,
            newUser.Email,
            DateTime.UtcNow
        );
        await _messageBus.PublishAsync(userRegisteredEvent);
        // 返回 200 OK，并附带成功消息
        return Ok("用户注册成功");
    }

    // POST api/auth/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
    {
        var user = await _userManager.FindByNameAsync(loginDto.Username);

        if (user == null || !await _userManager.CheckPasswordAsync(user, loginDto.Password))
        {
            // 返回 401 Unauthorized，表示认证失败
            return Unauthorized();
        }

        var token = _tokenService.GenerateJwtToken(user);

        var response = new AuthResponseDto(user.Id, user.UserName!, user.Email!, token, user.AvatarUrl);

        // 返回 200 OK，并在响应体中包含 AuthResponseDto 的 JSON 数据
        return Ok(response);
    }
    /// <summary>
    /// 使用有效的 JWT 获取当前用户的会话信息（实现自动登录）
    /// </summary>
    [HttpGet("session")]
    [Authorize] // 关键！这个接口必须要求请求头中带有有效的 JWT
    public async Task<IActionResult> GetSession()
    {
        // 从 JWT Token 中获取用户 ID
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null)
        {
            // 理论上 [Authorize] 会处理，但作为防御
            return Unauthorized();
        }

        // 从数据库中查找该用户以获取最新信息
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return Unauthorized("用户不存在或已被删除。");
        }

        // --- 重新生成一个新的 JWT Token (推荐做法) ---
        // 这可以实现“滑动会话”，每次用户活跃，令牌的有效期都会被刷新
        var newToken = _tokenService.GenerateJwtToken(user);

        // 返回与 Login 接口相同的 AuthResponseDto，但包含了新的令牌
        var response = new AuthResponseDto(user.Id, user.UserName!, user.Email!, newToken, user.AvatarUrl);

        return Ok(response);
    }
}