// SearchService/Controllers/SearchController.cs

using ChatProjects.SearchService.Data;
using ChatProjects.SearchService.Dtos;
using ChatProjects.SearchService.Models;
using Microsoft.AspNetCore.Mvc;
// 我们仍然保留 Models 的 using，但会在代码中显式指定

namespace ChatProjects.SearchService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SearchController : ControllerBase
{
    private readonly InMemoryDataStore _dataStore;

    public SearchController(InMemoryDataStore dataStore)
    {
        _dataStore = dataStore;
    }

    [HttpGet("groups")]
    public IActionResult SearchGroups([FromQuery] string? term, [FromQuery] string? tag)
    {
        // --- 核心修复：使用完整的命名空间来引用 Group ---
        var query = _dataStore.Groups.AsQueryable() as IQueryable<Group>;

        if (!string.IsNullOrWhiteSpace(term))
        {
            query = query.Where(g =>
                g.Name.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                g.Description.Contains(term, StringComparison.OrdinalIgnoreCase) // <-- 现在编译器知道 g.Description 是什么了
            );
        }

        if (!string.IsNullOrWhiteSpace(tag))
        {
            query = query.Where(g => g.Tags.Contains(tag, StringComparer.OrdinalIgnoreCase)); // <-- 现在编译器知道 g.Tags 是什么了
        }

        var results = query.ToList();

        // 这里的 g 会被正确推断为 SearchService.Models.Group
        var dtos = results.Select(g => new GroupSearchResultDto(
            g.Id,
            g.Name,
            g.AvatarUrl,
            g.MemberCount,
            g.OnlineStatus,
            g.Tags,
            g.Description
        )).ToList();

        return Ok(dtos);
    }
}