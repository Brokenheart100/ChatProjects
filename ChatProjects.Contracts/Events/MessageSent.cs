namespace ChatProjects.Contracts.Events;

// 当消息成功存储后，发布到 RabbitMQ 的事件
public record MessageSent(
    long MessageId,
    Guid ConversationId,
    string SenderId,
    string Content,
    DateTime SentAt
);