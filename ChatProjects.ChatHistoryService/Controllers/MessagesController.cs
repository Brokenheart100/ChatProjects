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
    private readonly ILogger<MessagesController> _logger;

    public MessagesController(
        ChatHistoryDbContext context,
        IMessageBus messageBus,
        ILogger<MessagesController> logger)
    {
        _context = context;
        _messageBus = messageBus;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] SendMessageDto dto)
    {
        // 📝 入口日志
        _logger.LogInformation("🚀 [SendMessage] 收到发送消息请求. 目标会话: {ConvId}, 类型: {Type}", dto.ConversationId, dto.ContentType);

        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId == null)
        {
            _logger.LogWarning("🚫 [SendMessage] 未授权访问: 无法获取 UserID");
            return Unauthorized();
        }

        _logger.LogInformation("👤 [SendMessage] 操作用户: {UserId}", currentUserId);

        // 1. 获取执行策略
        var strategy = _context.Database.CreateExecutionStrategy();

        // 2. 在执行策略中运行事务逻辑
        return await strategy.ExecuteAsync(async () =>
        {
            _logger.LogInformation("🛡️ [SendMessage] 开始执行数据库策略 (Execution Strategy)...");

            // 开启事务
            using var transaction = await _context.Database.BeginTransactionAsync();
            _logger.LogInformation("📝 [SendMessage] 数据库事务已开启");

            try
            {
                Guid conversationId = dto.ConversationId;
                bool isNewConversation = false;

                // ---------------------------------------------------------
                // 1. 会话检查与创建逻辑
                // ---------------------------------------------------------
                _logger.LogDebug("🔍 [SendMessage] 检查用户是否在会话参与者列表中...");

                var isParticipant = await _context.Participants
                    .AnyAsync(p => p.ConversationId == conversationId && p.UserId == currentUserId);

                if (isParticipant)
                {
                    _logger.LogDebug("✅ [SendMessage] 用户是现有会话成员");
                }
                else
                {
                    _logger.LogWarning("⚠️ [SendMessage] 用户不在会话中 (可能是新会话或假ID)，尝试自动创建逻辑...");

                    if (!string.IsNullOrEmpty(dto.RecipientId))
                    {
                        _logger.LogInformation("🕵️ [SendMessage] 尝试查找两人是否已存在私聊会话. RecipientId: {RecipientId}", dto.RecipientId);

                        // A. 尝试查找现有私聊
                        var existingConversationId = await _context.Conversations
                            .Where(c => c.Type == ConversationType.Private)
                            .Where(c => c.Participants.Any(p => p.UserId == currentUserId) &&
                                        c.Participants.Any(p => p.UserId == dto.RecipientId))
                            .Select(c => c.Id)
                            .FirstOrDefaultAsync();

                        if (existingConversationId != Guid.Empty)
                        {
                            _logger.LogInformation("🤝 [SendMessage] 找到已存在的私聊会话: {Id}. 修正前端传来的 ID", existingConversationId);
                            conversationId = existingConversationId;
                        }
                        else
                        {
                            // B. 创建新会话
                            conversationId = dto.ConversationId == Guid.Empty ? Guid.NewGuid() : dto.ConversationId;

                            _logger.LogInformation("✨ [SendMessage] 创建全新的私聊会话. ID: {Id}", conversationId);

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
                            _logger.LogInformation("👥 [SendMessage] 已添加参与者: {User1}, {User2}", currentUserId, dto.RecipientId);
                        }
                    }
                    else
                    {
                        _logger.LogWarning("⛔ [SendMessage] 拒绝访问: 用户不在会话中且未提供 RecipientId");
                        return StatusCode(403, "非会话成员且未指定接收人，无法发送消息。");
                    }
                }

                // ---------------------------------------------------------
                // 2. 消息存储
                // ---------------------------------------------------------

                var messageId = SnowflakeGenerator.NextId();
                var now = DateTime.UtcNow;

                _logger.LogInformation("🆔 [SendMessage] 生成消息 ID: {MsgId}", messageId);

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
                _logger.LogInformation("💾 [SendMessage] 消息实体已添加到 Context");

                // ---------------------------------------------------------
                // 3. 更新会话快照
                // ---------------------------------------------------------

                if (!isNewConversation)
                {
                    _logger.LogInformation("🔄 [SendMessage] 使用 ExecuteUpdateAsync 更新现有会话快照...");
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
                    _logger.LogInformation("🆕 [SendMessage] 更新新创建会话的内存实体快照...");
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

                _logger.LogInformation("✅ [SendMessage] 数据库事务提交成功! 消息已持久化.");

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

                _logger.LogInformation("📢 [SendMessage] 正在通过 Wolverine 发布 MessageSent 事件...");
                await _messageBus.PublishAsync(evt);
                _logger.LogInformation("📨 [SendMessage] 事件发布完成");

                return Ok(new
                {
                    Message = message,
                    RealConversationId = conversationId
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "🔥 [SendMessage] 发生严重错误，正在回滚事务...");
                await transaction.RollbackAsync();
                _logger.LogInformation("🔙 [SendMessage] 事务回滚完成");
                throw;
            }
        });
    }
}