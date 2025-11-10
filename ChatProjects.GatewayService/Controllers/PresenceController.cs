// 文件: ChatProjects.GatewayService/Controllers/SomeController.cs
using ChatProjects.Grains.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Orleans;

namespace ChatProjects.GatewayService.Controllers;

[ApiController]
[Route("[controller]")]
public class PresenceController : ControllerBase
{
    private readonly IGrainFactory _grainFactory;

    public PresenceController(IGrainFactory grainFactory)
    {
        _grainFactory = grainFactory;
    }

    [HttpGet("{userId}/isonline")]
    public async Task<IActionResult> IsUserOnline(string userId)
    {
        // 你不需要知道 UserGrain 在哪个服务器上，只需要“召唤”它
        var userGrain = _grainFactory.GetGrain<IUserGrain>(userId);

        var isOnline = await userGrain.IsOnline();

        return Ok(new { UserId = userId, IsOnline = isOnline });
    }
}