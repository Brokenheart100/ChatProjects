using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ChatProjects.UserService.Data;

namespace ChatProjects.UserService.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly UserDbContext _context;
    // 1. 声明 Logger
    private readonly ILogger<UsersController> _logger;

    // 2. 在构造函数中注入 Logger
    public UsersController(UserDbContext context, ILogger<UsersController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// 批量获取用户信息
    /// </summary>
    [HttpPost("batch")]
    public async Task<IActionResult> GetUsersBatch([FromBody] List<string> userIds)
    {
        // 📝 入口日志：打印接收到的数量
        _logger.LogInformation("🚀 [GetUsersBatch] 收到批量用户查询请求. 请求数量: {Count}", userIds?.Count ?? 0);

        // 1. 如果列表为空，直接返回空
        if (userIds == null || !userIds.Any())
        {
            _logger.LogWarning("⚠️ [GetUsersBatch] 请求 ID 列表为空，直接返回空数组");
            return Ok(new List<object>());
        }

        // 📝 调试日志：打印具体请求的 ID (方便排查 ID 格式是否正确)
        // string.Join 可能会很长，生产环境建议用 LogDebug
        _logger.LogInformation("📋 [GetUsersBatch] 待查询 ID 列表: {Ids}", string.Join(", ", userIds));

        // 2. 去数据库查询
        _logger.LogInformation("🔍 [GetUsersBatch] 开始查询数据库 UserProfiles 表...");

        try
        {
            // 假设你的用户表叫 UserProfiles，主键是 UserId
            var users = await _context.UserProfiles
                .Where(u => userIds.Contains(u.UserId)) // <--- 再次确认为 UserId
                .Select(u => new
                {
                    // 注意：这里返回的属性名必须跟 ChatHistoryService 的 DTO 对应
                    Id = u.UserId,
                    Username = u.DisplayName ?? u.UserName, // 优先显示昵称
                    AvatarUrl = u.AvatarUrl
                })
                .ToListAsync();

            // 📝 结果分析日志
            if (users.Count == 0)
            {
                _logger.LogError("😱 [GetUsersBatch] 灾难！请求了 {ReqCount} 个 ID，但数据库里一个都没找到！(可能是 ID 格式/大小写不匹配)", userIds.Count);
            }
            else if (users.Count < userIds.Count)
            {
                _logger.LogWarning("❓ [GetUsersBatch] 部分匹配：请求 {ReqCount} 个，实际找到 {ResCount} 个 (有 {Diff} 个 ID 不存在)",
                    userIds.Count, users.Count, userIds.Count - users.Count);
            }
            else
            {
                _logger.LogInformation("✅ [GetUsersBatch] 完美匹配！成功获取 {Count} 个用户资料", users.Count);
            }

            return Ok(users);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "🔥 [GetUsersBatch] 查询数据库时发生严重异常");
            throw;
        }
    }
}