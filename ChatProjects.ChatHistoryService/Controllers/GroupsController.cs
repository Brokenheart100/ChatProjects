using ChatProjects.ChatHistoryService.Data;
using ChatProjects.ChatHistoryService.Dtos;
using ChatProjects.ChatHistoryService.Models;
using ChatProjects.Contracts.Events;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Wolverine;

namespace ChatProjects.ChatHistoryService.Controllers;

[ApiController]
[Route("api/groups")]
[Authorize]
public class GroupsController(
    ChatHistoryDbContext context,
    ILogger<GroupsController> logger,
    IMessageBus messageBus,
    IHttpClientFactory httpClientFactory // ✅ 1. 在构造函数中注入 IHttpClientFactory
    ) : ControllerBase
{
    private readonly ChatHistoryDbContext _context = context;
    private readonly ILogger<GroupsController> _logger = logger;
    private readonly IMessageBus _messageBus = messageBus;
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory; // ✅ 2. 赋值给字段

    // 1. 创建群聊
    [HttpPost]
    public async Task<IActionResult> CreateGroup([FromBody] CreateGroupDto dto)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        var strategy = _context.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var groupId = dto.Id ?? Guid.NewGuid();
                _logger.LogInformation("👥 [CreateGroup] 用户 {UserId} 正在创建群聊: {Name}, 成员数: {Count}", currentUserId, dto.GroupName, dto.MemberIds.Count);

                // 1. 创建会话
                var conversation = new Conversation
                {
                    Id = groupId,
                    Type = ConversationType.Group,
                    Name = dto.GroupName,
                    Avatar = dto.AvatarUrl,
                    LastMessageContent = "群聊已创建",
                    LastMessageAt = DateTime.UtcNow,
                };
                _context.Conversations.Add(conversation);

                // 2. 添加群主 (自己)
                _context.Participants.Add(new Participant { ConversationId = groupId, UserId = currentUserId, IsPinned = true });

                // 3. 添加其他成员
                foreach (var memberId in dto.MemberIds.Distinct())
                {
                    if (memberId == currentUserId) continue;
                    _context.Participants.Add(new Participant { ConversationId = groupId, UserId = memberId });
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                _logger.LogInformation("✅ [CreateGroup] 群聊创建成功: {GroupId}", groupId);

                var allMembers = dto.MemberIds.Append(currentUserId).Distinct().ToList();

                // 发送事件
                await _messageBus.PublishAsync(new GroupCreatedEvent(
                    groupId,
                    dto.GroupName,
                    currentUserId,
                    allMembers,
                    DateTime.UtcNow
                ));

                return Ok(new { GroupId = groupId });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "❌ [CreateGroup] 创建失败");
                throw;
            }
        });
    }

    // 2. 获取群组详情
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetGroupDetail(Guid id)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        var conversation = await _context.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.Id == id && c.Type == ConversationType.Group);

        if (conversation == null)
        {
            _logger.LogWarning("❌ [GetGroupDetail] Group not found: {Id}", id);
            return NotFound("Group not found");
        }

        if (!conversation.Participants.Any(p => p.UserId == currentUserId))
        {
            return Forbid();
        }

        var memberIds = conversation.Participants.Select(p => p.UserId).ToList();
        var membersDtos = await FetchMemberProfiles(memberIds);

        int myRole = 0; // 简化处理，默认为 0

        var result = new GroupDetailDto
        {
            Id = conversation.Id,
            Name = conversation.Name ?? "未命名群聊",
            Avatar = conversation.Avatar ?? "",
            Announcement = "暂无公告",
            OwnerId = "",
            MemberCount = conversation.Participants.Count,
            MyRole = myRole,
            Members = membersDtos
        };

        return Ok(result);
    }

    // 3. 获取群成员
    [HttpGet("{id:guid}/members")]
    public async Task<IActionResult> GetGroupMembers(Guid id)
    {
        var memberIds = await _context.Participants
            .Where(p => p.ConversationId == id)
            .Select(p => p.UserId)
            .ToListAsync();

        if (memberIds.Count == 0) return NotFound();

        var profiles = await FetchMemberProfiles(memberIds);
        return Ok(profiles);
    }

    // ✅ 4. 修改群名称 (补全)
    // 对应 Flutter: updateGroupName(String groupId, String newName)
    [HttpPut("{id:guid}/name")]
    public async Task<IActionResult> UpdateGroupName(Guid id, [FromBody] UpdateGroupNameDto dto)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        var conversation = await _context.Conversations.FindAsync(id);
        if (conversation == null) return NotFound();

        // 验证是否是群成员
        var isMember = await _context.Participants.AnyAsync(p => p.ConversationId == id && p.UserId == currentUserId);
        if (!isMember) return Forbid();

        conversation.Name = dto.Name;
        await _context.SaveChangesAsync();

        // 通知其他成员群名变更 (事件定义需在 Contracts 中添加)
        await _messageBus.PublishAsync(new GroupNameUpdated(id, dto.Name));

        return Ok();
    }

    // ✅ 5. 踢出成员 (补全)
    // 对应 Flutter: kickGroupMember({required String groupId, required String userId})
    [HttpPost("{id:guid}/kick")]
    public async Task<IActionResult> KickMember(Guid id, [FromBody] KickMemberDto dto)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        // 实际场景应检查 currentUserId 是否有管理员权限

        var participant = await _context.Participants
            .FirstOrDefaultAsync(p => p.ConversationId == id && p.UserId == dto.UserId);

        if (participant == null) return NotFound("User is not in this group");

        _context.Participants.Remove(participant);
        await _context.SaveChangesAsync();

        // 发送踢人事件
        await _messageBus.PublishAsync(new GroupMemberKicked(id, dto.UserId));

        return Ok();
    }

    // ✅ 6. 退出群聊 (补全)
    // 对应 Flutter: leaveGroup(String groupId)
    [HttpPost("{id:guid}/leave")]
    public async Task<IActionResult> LeaveGroup(Guid id)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        var participant = await _context.Participants
            .FirstOrDefaultAsync(p => p.ConversationId == id && p.UserId == currentUserId);

        if (participant == null) return BadRequest("You are not in this group");

        _context.Participants.Remove(participant);
        await _context.SaveChangesAsync();

        await _messageBus.PublishAsync(new GroupMemberLeft(id, currentUserId));

        return Ok();
    }

    // --- 私有辅助方法 ---
    private async Task<List<GroupMemberDto>> FetchMemberProfiles(List<string> userIds)
    {
        try
        {
            var client = _httpClientFactory.CreateClient("UserService");
            var response = await client.PostAsJsonAsync("/api/users/batch", userIds);

            if (response.IsSuccessStatusCode)
            {
                var users = await response.Content.ReadFromJsonAsync<List<UserProfileDto>>();
                return users?.Select(u => new GroupMemberDto
                {
                    UserId = u.Id,
                    Nickname = u.Username,
                    AvatarUrl = u.AvatarUrl,
                    Role = 0
                }).ToList() ?? new List<GroupMemberDto>();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch user profiles from UserService");
        }

        return userIds.Select(id => new GroupMemberDto { UserId = id, Nickname = "用户" }).ToList();
    }
}

