using ChatProjects.ChatHistoryService.Data;
using ChatProjects.ChatHistoryService.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace ChatProjects.ChatHistoryService.Controllers;

[ApiController]
[Route("api/conversations")]
[Authorize]
public class ConversationsController(
    ChatHistoryDbContext context,
    IHttpClientFactory httpClientFactory,
    ILogger<ConversationsController> logger) : ControllerBase
{
    private readonly ChatHistoryDbContext _context = context;
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;
    // 1. 注入 Logger
    private readonly ILogger<ConversationsController> _logger = logger;

    [HttpGet]
    public async Task<IActionResult> GetList()
    {
        _logger.LogInformation("🚀 [GetList] 收到获取会话列表请求");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null)
        {
            _logger.LogWarning("🚫 [GetList] 无法获取当前用户 ID (Unauthorized)");
            return Unauthorized();
        }

        _logger.LogInformation("👤 [GetList] 当前用户: {UserId}", userId);

        // 1. 查会话基本信息
        _logger.LogInformation("🔍 [GetList] 正在从数据库查询参与的会话 ID...");

        var myConversationIds = _context.Participants
            .Where(p => p.UserId == userId)
            .Select(p => p.ConversationId);

        _logger.LogInformation("📋 [GetList] 正在查询会话详情 (按时间倒序)...");

        var rawConversations = await _context.Conversations
            .Where(c => myConversationIds.Contains(c.Id))
            .OrderByDescending(c => c.LastMessageAt)
            .Select(c => new
            {
                c.Id,
                c.LastMessageContent,
                c.LastMessageAt,
                RecipientId = _context.Participants
                    .Where(p => p.ConversationId == c.Id && p.UserId != userId)
                    .Select(p => p.UserId)
                    .FirstOrDefault()
            })
            .ToListAsync();

        _logger.LogInformation("📥 [GetList] 数据库查询完成，找到 {Count} 个原始会话", rawConversations.Count);

        // 2. 提取所有需要查询的 UserID
        var recipientIds = rawConversations
            .Where(c => !string.IsNullOrEmpty(c.RecipientId))
            .Select(c => c.RecipientId!)
            .Distinct()
            .ToList();

        _logger.LogInformation("👥 [GetList] 需要聚合用户信息的 ID 数量: {Count}", recipientIds.Count);

        // 3. 调用 UserService 批量查询
        List<UserProfileDto> userProfiles = new();
        if (recipientIds.Count != 0)
        {
            try
            {
                _logger.LogInformation("🌐 [GetList] 正在调用 UserService 批量查询接口: /api/users/batch");

                var client = _httpClientFactory.CreateClient("UserService");
                var response = await client.PostAsJsonAsync("/api/users/batch", recipientIds);

                if (response.IsSuccessStatusCode)
                {
                    userProfiles = await response.Content.ReadFromJsonAsync<List<UserProfileDto>>()
                                   ?? new List<UserProfileDto>();
                    _logger.LogInformation("✅ [GetList] UserService 调用成功，获取到 {Count} 个用户资料", userProfiles.Count);
                }
                else
                {
                    _logger.LogWarning("⚠️ [GetList] UserService 返回非成功状态码: {StatusCode}", response.StatusCode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [GetList] 调用 UserService 发生异常 (降级处理，仅显示 ID)");
            }
        }
        else
        {
            _logger.LogInformation("⏩ [GetList] 没有私聊对象，跳过 UserService 调用");
        }

        // 4. 组装最终数据
        _logger.LogInformation("🧩 [GetList] 正在组装最终 DTO 数据...");

        var result = rawConversations.Select(c =>
        {
            var user = userProfiles.FirstOrDefault(u => u.Id == c.RecipientId);
            var displayName = user?.Username ?? c.RecipientId ?? "群聊";

            // 可选：打印详细的匹配日志（调试用，生产环境可去掉）
            // _logger.LogDebug("   🔗 匹配会话 {ConvId} -> 用户 {UserId} ({Name})", c.Id, c.RecipientId, displayName);

            return new ConversationListDto
            {
                Id = c.Id,
                RecipientId = c.RecipientId ?? "",
                Name = displayName,
                Avatar = user?.AvatarUrl ?? "",
                LastMessage = c.LastMessageContent ?? "",
                LastMessageAt = c.LastMessageAt
            };
        }).ToList(); // 立即执行以完成 Select

        _logger.LogInformation("🏁 [GetList] 请求处理完成，返回 {Count} 条会话数据", result.Count);

        return Ok(result);
    }

    // GET /api/conversations/{id}/messages?beforeTimestamp=...&limit=20
    [HttpGet("{id:guid}/messages")]
    public async Task<IActionResult> GetMessages(
        Guid id, [FromQuery] DateTime? beforeTimestamp, [FromQuery] int limit = 20)
    {
        _logger.LogInformation("🚀 [GetMessages] 收到获取历史消息请求. 会话ID: {ConvId}", id);

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null)
        {
            _logger.LogWarning("🚫 [GetMessages] 未授权用户");
            return Unauthorized();
        }

        // 1. 检查会话是否存在
        _logger.LogInformation("🔍 [GetMessages] 检查会话是否存在...");

        var conversationExists = await _context.Conversations
            .AnyAsync(c => c.Id == id);

        if (!conversationExists)
        {
            _logger.LogInformation("👻 [GetMessages] 会话不存在 (前端生成的临时 UUID: {ConvId})，返回空列表", id);
            return Ok(new List<object>());
        }

        // 2. 权限验证
        _logger.LogInformation("🛡️ [GetMessages] 验证用户 {UserId} 是否在会话中...", userId);

        var isParticipant = await _context.Participants.AnyAsync(p => p.ConversationId == id && p.UserId == userId);
        if (!isParticipant)
        {
            _logger.LogWarning("⛔ [GetMessages] 权限拒绝！用户 {UserId} 不是会话 {ConvId} 的成员", userId, id);
            return StatusCode(403, "您无权查看此会话的历史记录。");
        }

        // 3. 查询消息
        var effectiveTimestamp = beforeTimestamp ?? DateTime.UtcNow;
        _logger.LogInformation("📜 [GetMessages] 开始查询消息表. 时间点: < {Time}, 数量: {Limit}", effectiveTimestamp, limit);

        var messages = await _context.Messages
            .Where(m => m.ConversationId == id && m.SentAt < effectiveTimestamp)
            .OrderByDescending(m => m.SentAt)
            .Take(limit)
            .ToListAsync();

        _logger.LogInformation("🏁 [GetMessages] 查询成功，返回 {Count} 条消息", messages.Count);

        return Ok(messages);
    }
}