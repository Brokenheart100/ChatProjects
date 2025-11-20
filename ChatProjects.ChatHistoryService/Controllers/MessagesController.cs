using System.Security.Claims;
using ChatProjects.ChatHistoryService.Data;
using ChatProjects.ChatHistoryService.Dtos;
using ChatProjects.ChatHistoryService.Models;
using ChatProjects.ChatHistoryService.Utils;
using ChatProjects.Contracts.Events;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Wolverine;

namespace ChatProjects.ChatHistoryService.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class MessagesController : ControllerBase
{
    private readonly ChatHistoryDbContext _context;
    private readonly IMessageBus _messageBus;

    public MessagesController(ChatHistoryDbContext context, IMessageBus messageBus)
    {
        _context = context;
        _messageBus = messageBus;
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageDto dto)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null) return Unauthorized();

        // 1. 获取执行策略 (解决 NpgsqlRetryingExecutionStrategy 报错的关键)
        var strategy = _context.Database.CreateExecutionStrategy();

        // 2. 在执行策略中运行事务逻辑
        return await strategy.ExecuteAsync(async () =>
        {
            // 开启事务
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                Guid conversationId = dto.ConversationId;
                bool isNewConversation = false;

                // ---------------------------------------------------------
                // 1. 会话检查与创建逻辑
                // ---------------------------------------------------------

                var isParticipant = await _context.Participants
                    .AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

                if (!isParticipant)
                {
                    if (!string.IsNullOrEmpty(dto.RecipientId))
                    {
                        // A. 尝试查找现有私聊
                        var existingConversationId = await _context.Participants
                            .Where(p => p.UserId == currentUserId)
                            .Join(_context.Participants.Where(p => p.UserId == dto.RecipientId),
                                  p1 => p1.ConversationId,
                                  p2 => p2.ConversationId,
                                  (p1, p2) => p1.ConversationId)
                            .Join(_context.Conversations.Where(c => c.Type == ConversationType.Private),
                                  id => id,
                                  c => c.Id,
                                  (id, c) => c.Id)
                            .FirstOrDefaultAsync();

                        if (existingConversationId != Guid.Empty)
                        {
                            conversationId = existingConversationId;
                        }
                        else
                        {
                            // B. 创建新会话
                            conversationId = dto.ConversationId == Guid.Empty ? Guid.NewGuid() : dto.ConversationId;

                            var newConversation = new Conversation
                            {
                                Id = conversationId,
                                Type = ConversationType.Private,
                                CreatedAt = DateTime.UtcNow,
                                LastMessageAt = DateTime.UtcNow
                            };

                            _context.Conversations.Add(newConversation);

                            _context.Participants.Add(new Participant { ConversationId = conversationId, UserId = currentUserId });
                            _context.Participants.Add(new Participant { ConversationId = conversationId, UserId = dto.RecipientId });

                            isNewConversation = true;
                        }
                    }
                    else
                    {
                        // 这里不能直接 return，因为我们在 Lambda 表达式中
                        // 需要抛出异常或返回特定的 Result，但在 Controller Action 中，
                        // 直接返回 IActionResult 是最方便的。
                        // 为了跳出 ExecuteAsync，我们直接 return 一个 ForbidResult
                        return StatusCode(403, "非会话成员且未指定接收人，无法发送消息。");
                    }
                }

                // ---------------------------------------------------------
                // 2. 消息存储
                // ---------------------------------------------------------

                var messageId = SnowflakeGenerator.NextId();
                var now = DateTime.UtcNow;

                var message = new Message
                {
                    Id = messageId,
                    ConversationId = conversationId,
                    SenderId = currentUserId,
                    Content = dto.Content,
                    ContentType = dto.ContentType,
                    SentAt = now
                };

                _context.Messages.Add(message);

                // ---------------------------------------------------------
                // 3. 更新会话快照
                // ---------------------------------------------------------

                if (!isNewConversation)
                {
                    await _context.Conversations
                        .Where(c => c.Id == conversationId)
                        .ExecuteUpdateAsync(calls => calls
                            .SetProperty(c => c.LastMessageContent, dto.ContentType == 0 ? dto.Content : "[图片]")
                            .SetProperty(c => c.LastMessageAt, now)
                            .SetProperty(c => c.LastMessageId, messageId)
                        );
                }
                else
                {
                    var entry = _context.ChangeTracker.Entries<Conversation>()
                        .FirstOrDefault(e => e.Entity.Id == conversationId);
                    if (entry != null)
                    {
                        entry.Entity.LastMessageContent = dto.ContentType == 0 ? dto.Content : "[图片]";
                        entry.Entity.LastMessageAt = now;
                        entry.Entity.LastMessageId = messageId;
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // ---------------------------------------------------------
                // 4. 异步事件推送
                // ---------------------------------------------------------

                var evt = new MessageSent(
                    message.Id,
                    message.ConversationId,
                    message.SenderId,
                    message.Content,
                    message.SentAt
                );

                await _messageBus.PublishAsync(evt);

                return Ok(new
                {
                    Message = message,
                    RealConversationId = conversationId
                });
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw; // 抛出异常让外层处理或重试
            }
        });
    }
}