using ChatProjects.RealtimeService.Services;
using Microsoft.AspNetCore.Mvc;

namespace ChatProjects.RealtimeService.Controllers;

[ApiController]
[Route("api/status")]
public class StatusController(UserStatusService statusService) : ControllerBase
{
    [HttpPost("batch-check")]
    public async Task<IActionResult> CheckOnlineStatus([FromBody] List<string> userIds)
    {
        var result = await statusService.AreUsersOnlineAsync(userIds);
        return Ok(result);
    }
}