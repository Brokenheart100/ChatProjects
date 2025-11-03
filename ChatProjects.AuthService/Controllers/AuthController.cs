using ChatProjects.AuthService.Dtos;
using ChatProjects.AuthService.Models;
using ChatProjects.AuthService.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace ChatProjects.AuthService.Controllers;

[ApiController] // 标记这是一个 API 控制器，会自动启用模型验证等功能
[Route("api/[controller]")] // 定义路由模板，这里会自动解析为 "api/auth"
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly TokenService _tokenService;

    // 通过构造函数注入所有需要的服务
    public AuthController(UserManager<AppUser> userManager, TokenService tokenService)
    {
        _userManager = userManager;
        _tokenService = tokenService;
    }

    // POST api/auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto registerDto)
    {
        // 模型验证由 [ApiController] 自动处理，如果无效会直接返回 400 Bad Request

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
            SecurityStamp = Guid.NewGuid().ToString()
        };

        var result = await _userManager.CreateAsync(newUser, registerDto.Password);

        if (!result.Succeeded)
        {
            // 返回 400 Bad Request，并附带 Identity 框架生成的具体错误信息
            return BadRequest(result.Errors);
        }

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

        var response = new AuthResponseDto(user.Id, user.UserName!, user.Email!, token);

        // 返回 200 OK，并在响应体中包含 AuthResponseDto 的 JSON 数据
        return Ok(response);
    }
}