// 文件: ChatProjects.Contracts/Handlers/MessageEventHandler.cs

using ChatProjects.Contracts.Events; // <-- 添加 using
using Microsoft.Extensions.Logging;
using Typesense; // <-- 确保有这个 using

namespace ChatProjects.Contracts.Handlers;

public class MessageEventHandler
{
    private readonly ITypesenseClient _typesenseClient;
    private readonly ILogger<MessageEventHandler> _logger;

    public MessageEventHandler(ITypesenseClient typesenseClient, ILogger<MessageEventHandler> logger)
    {
        _typesenseClient = typesenseClient;
        _logger = logger;
    }

    public async Task Consume(MessageSent messageEvent)
    {
        _logger.LogInformation("Indexing message {MessageId} to Typesense", messageEvent.MessageId);

        var messageDocument = new
        {
            id = messageEvent.MessageId.ToString(),
            conversation_id = messageEvent.ConversationId.ToString(),
            sender_id = messageEvent.SenderId,
            content = messageEvent.Content,
            sent_at = new DateTimeOffset(messageEvent.SentAt).ToUnixTimeSeconds()
        };

        try
        {
            //await _typesenseClient.CreateCollection()
            _logger.LogInformation("Successfully indexed message {MessageId}", messageEvent.MessageId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to index message {MessageId} to Typesense", messageEvent.MessageId);
            // 这里可以根据需要添加重试逻辑
        }
    }
}