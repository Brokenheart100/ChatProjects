using ChatProjects.Contracts.Events;
using ChatProjects.UserService.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using StackExchange.Redis;
using Wolverine;

namespace ChatProjects.UserService.Controllers;

[ApiController]
[Route("api/users/status")]
public class StatusController(
    UserDbContext context,
    IMessageBus bus,
    ILogger<StatusController> logger,
    IConnectionMultiplexer redis) : ControllerBase // ✅ 注入 Redis
{
    [HttpPost("online")]
    public async Task<IActionResult> ReportOnline()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        // 1. ✅ 写入 Redis (设置 2 分钟过期，前端需要每分钟发心跳续期)
        var db = redis.GetDatabase();
        await db.StringSetAsync($"user:online:{userId}", "1", TimeSpan.FromMinutes(2));

        // 2. 原有的广播逻辑 (保持不变)
        var friendIds = await context.Friendships
            .Where(f => f.User1Id == userId || f.User2Id == userId)
            .Select(f => f.User1Id == userId ? f.User2Id : f.User1Id)
            .ToListAsync();

        if (friendIds.Count > 0)
        {
            await bus.PublishAsync(new UserStatusChangedEvent(userId, "online", friendIds));
        }

        return Ok();
    }
}