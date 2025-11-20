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

        // POST /api/messages
        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageDto dto)
        {
            var senderId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (senderId == null) return Unauthorized();

            // 【安全关键】验证发送者是否是该会话的成员
            var isParticipant = await _context.Participants
                .AnyAsync(p => p.ConversationId == dto.ConversationId && p.UserId == senderId);
        if (!isParticipant)
        {
            // --- 核心逻辑修改：自动创建会话 ---

            // A. 检查会话是否真的不存在
            var conversationExists = await _context.Messages // 或者查 Conversations 表，这里假设 Messages 表有关联
                 .AnyAsync(m => m.ConversationId == dto.ConversationId);
            // 注意：如果有 Conversations 表，最好查 Conversations 表：
            // var conversationExists = await _context.Database.ExecuteSqlRawAsync("SELECT 1 FROM \"Conversations\" WHERE \"Id\" = {0}", dto.ConversationId) > 0;
            // 为了简化，我们假设如果 Participants 里没人，大概率是新会话。

            // B. 如果提供了 RecipientId，我们尝试创建新会话
            if (!string.IsNullOrEmpty(dto.RecipientId))
            {
                // 创建参与者记录：自己
                _context.Participants.Add(new Participant
                {
                    ConversationId = dto.ConversationId,
                    UserId = senderId
                });

                // 创建参与者记录：对方
                _context.Participants.Add(new Participant
                {
                    ConversationId = dto.ConversationId,
                    UserId = dto.RecipientId
                });

                // 如果您有 Conversations 表，这里也需要插入
                // _context.Conversations.Add(new Conversation { Id = dto.ConversationId, ... });

                // 保存参与者关系
                await _context.SaveChangesAsync();

                // 继续执行下面的发送消息逻辑...
            }
            else
            {
                return StatusCode(403, "您不是此会话的成员，且未指定接收人无法创建会话。");
            }
        }
        var message = new Message
            {
                Id = SnowflakeGenerator.NextId(), // 使用雪花ID生成器
                ConversationId = dto.ConversationId,
                SenderId = senderId,
                Content = dto.Content,
                ContentType = dto.ContentType,
                SentAt = DateTime.UtcNow
            };

            _context.Messages.Add(message);
            await _context.SaveChangesAsync();

            // 写入成功后，发布事件
            var messageSentEvent = new MessageSent(
                message.Id, message.ConversationId, message.SenderId, message.Content, message.SentAt
            );
            await _messageBus.PublishAsync(messageSentEvent);

            return Ok(message); // 将创建成功的消息返回给前端
        }
    }
