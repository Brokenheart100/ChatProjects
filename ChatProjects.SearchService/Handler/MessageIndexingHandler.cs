using ChatProjects.Contracts.Events;
using Typesense;

namespace ChatProjects.SearchService.Handlers;

public class MessageIndexingHandler
{
    private readonly ITypesenseClient _client;
    private readonly ILogger<MessageIndexingHandler> _logger;

    public MessageIndexingHandler(ITypesenseClient client, ILogger<MessageIndexingHandler> logger)
    {
        _client = client;
        _logger = logger;
    }

    // Wolverine 会自动调用这个 Handle 方法
    public async Task Handle(MessageSent evt)
    {
        _logger.LogInformation("🔍 [Indexing] Indexing message: {Id} from Conv: {ConvId}", evt.MessageId,evt.ConversationId);

        // 构造要索引的文档
        // 注意：Typesense 推荐字段名用下划线命名法
        var document = new
        {
            id = evt.MessageId.ToString(),
            conversation_id = evt.ConversationId.ToString(),
            sender_id = evt.SenderId,
            content = evt.Content,
            // 将 DateTime 转为 Unix 时间戳 (秒)，方便排序
            sent_at = new DateTimeOffset(evt.SentAt).ToUnixTimeSeconds()
        };

        // 使用 Upsert：如果 ID 存在则更新，不存在则插入
        await _client.UpsertDocument("messages", document);
    }
}