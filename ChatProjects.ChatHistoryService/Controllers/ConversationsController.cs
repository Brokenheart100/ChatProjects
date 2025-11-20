using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using ChatProjects.ChatHistoryService.Data;

namespace ChatProjects.ChatHistoryService.Controllers;




[ApiController]
[Route("api/conversations")]
[Authorize]
public class ConversationsController : ControllerBase
{
    private readonly ChatHistoryDbContext _context;

    public ConversationsController(ChatHistoryDbContext context)
    {
        _context = context;
    }

    // GET /api/conversations/{id}/messages?beforeTimestamp=...&limit=20
    [HttpGet("{id:guid}/messages")]
    public async Task<IActionResult> GetMessages(
        Guid id, [FromQuery] DateTime? beforeTimestamp, [FromQuery] int limit = 20)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        // 【安全关键】同样需要验证用户权限
        var isParticipant = await _context.Participants.AnyAsync(p => p.ConversationId == id && p.UserId == userId);
        if (!isParticipant)
        {
            // --- 核心修复 ---
            return StatusCode(403, "您无权查看此会话的历史记录。");
            // ----------------
        }

        // 如果没有提供时间戳，则从现在开始查询
        var effectiveTimestamp = beforeTimestamp ?? DateTime.UtcNow;

        var messages = await _context.Messages
            .Where(m => m.ConversationId == id && m.SentAt < effectiveTimestamp)
            .OrderByDescending(m => m.SentAt) // 利用我们创建的关键索引
            .Take(limit)
            .ToListAsync();

        return Ok(messages);
    }
}