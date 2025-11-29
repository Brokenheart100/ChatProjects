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
public class GroupsController(ChatHistoryDbContext context, ILogger<GroupsController> logger, IMessageBus messageBus) : ControllerBase
{
    private readonly ChatHistoryDbContext _context = context;
    private readonly ILogger<GroupsController> _logger = logger;
    private readonly IMessageBus _messageBus=messageBus;

    [HttpPost]
    public async Task<IActionResult> CreateGroup([FromBody] CreateGroupDto dto)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        // 1. 获取执行策略 (核心修复)
        var strategy = _context.Database.CreateExecutionStrategy();

        // 2. 在执行策略中运行事务逻辑
        return await strategy.ExecuteAsync(async () =>
        {
            // 开启事务
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
                    Name = dto.GroupName, // 存群名
                    Avatar = "", // 默认无头像
                    LastMessageContent = "群聊已创建",
                    LastMessageAt = DateTime.UtcNow,
                };
                _context.Conversations.Add(conversation);

                // 2. 添加群主 (自己)
                _context.Participants.Add(new Participant { ConversationId = groupId, UserId = currentUserId, IsPinned = true });

                // 3. 添加其他成员
                foreach (var memberId in dto.MemberIds.Distinct())
                {
                    // 避免重复添加自己
                    if (memberId == currentUserId) continue;
                    _context.Participants.Add(new Participant { ConversationId = groupId, UserId = memberId });
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                _logger.LogInformation("✅ [CreateGroup] 群聊创建成功: {GroupId}", groupId);


                var allMembers = dto.MemberIds.Append(currentUserId).Distinct().ToList();

                await _messageBus.PublishAsync(new GroupCreatedEvent(
                    groupId,
                    dto.GroupName,
                    currentUserId,
                    allMembers,
                    DateTime.UtcNow
                ));


                // 这里虽然没有发 System Event，但为了简化先返回成功
                return Ok(new { GroupId = groupId });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "❌ [CreateGroup] 创建失败");
                throw; // 必须抛出异常，以便 ExecutionStrategy 知道操作失败了
            }
        });
    }
}