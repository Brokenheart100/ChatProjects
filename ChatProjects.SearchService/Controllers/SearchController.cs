using System;
using ChatProjects.Contracts.Dtos;
using ChatProjects.SearchService.Data;
using ChatProjects.SearchService.Dtos;
using ChatProjects.SearchService.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
// 我们仍然保留 Models 的 using，但会在代码中显式指定

namespace ChatProjects.SearchService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SearchController : ControllerBase
{
    private readonly InMemoryDataStore _dataStore;
    private readonly UserDbContext _context;
    public SearchController(InMemoryDataStore dataStore, UserDbContext context)
    {
        _dataStore = dataStore;
        _context = context;
    }

    [HttpGet("groups")]
    public IActionResult SearchGroups([FromQuery] string? term, [FromQuery] string? tag)
    {
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

    // GET /api/search/users?query=...
    [HttpGet("users")]
    public async Task<IActionResult> SearchUsers([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new List<UserSearchResultDto>());
        }

        // 为了安全，不要在 LIKE 中使用 %query%
        var formattedQuery = $"{query}%";

        // 从 AspNetUsers 表中模糊搜索用户名匹配的用户
        var users = await _context.Users
            .Where(u => EF.Functions.ILike(u.UserName, formattedQuery))
            .Take(10) // 限制最多返回10条结果
            .Select(u => new UserSearchResultDto(
                u.Id,
                u.UserName,
                u.AvatarUrl,
                "NotFriend" // 这里的逻辑需要完善，需要查询关系表
            ))
            .ToListAsync();

        return Ok(users);
    }
}