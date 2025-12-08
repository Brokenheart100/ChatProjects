using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ChatProjects.SearchService.Dtos;
using Typesense;

namespace ChatProjects.SearchService.Controllers;

//TypesenseController
[ApiController]
[Route("api/search")]
[Authorize] // 必须登录
public class TypesenseController : ControllerBase
{
    private readonly ITypesenseClient _client;
    private readonly ILogger<TypesenseController> _logger;

    public TypesenseController(ITypesenseClient client, ILogger<TypesenseController> logger)
    {
        _client = client;
        _logger = logger;
    }

    [HttpGet("messages")]
    public async Task<IActionResult> SearchMessages(
        [FromQuery] string q,
        [FromQuery] Guid conversationId)
    {
        if (string.IsNullOrWhiteSpace(q)) return Ok(new List<object>());

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        // 🛡️ 安全检查 (企业级必须)：
        // 确保当前用户真的在这个 conversationId 里。
        // 在微服务架构中，你有两个选择：
        // 1. 调用 ChatHistoryService/UserService 验证成员资格 (最安全，但有网络开销)。
        // 2. 相信前端传来的 conversationId，假设 Gateway 层已经做过初步拦截 (性能最好，但有风险)。

        // 这里为了演示核心搜索逻辑，暂时略过远程调用，实际项目中建议加上缓存验证。
        _logger.LogInformation("🔎 [Search] User {User} searching '{Query}' in {Conv}", userId, q, conversationId);

        var query = new SearchParameters(q, "content")
        {
            FilterBy = $"conversation_id:={conversationId}",
            SortBy = "sent_at:desc",
            PerPage = 20,
            HighlightFullFields = "content"
        };

        try
        {
            var result = await _client.Search<MessageIndexDto>("messages", query);

            // 转换结果，返回给前端
            var response = result.Hits.Select(hit => new
            {
                MessageId = hit.Document.Id,
                Content = hit.Document.Content,
                SenderId = hit.Document.SenderId,
                SentAt = DateTimeOffset.FromUnixTimeSeconds(hit.Document.SentAt).DateTime,
                // ✅ 返回高亮片段 (例如: "你好 <mark>世界</mark>")
                Highlights = hit.Highlights.FirstOrDefault(h => h.Field == "content")?.Snippet
                             ?? hit.Document.Content
            });

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Search failed");
            return StatusCode(500, "Search service error");
        }
    }
}
