using ChatProjects.Contracts.Events;
using MQTTnet;
using MQTTnet.Extensions.ManagedClient;
using System.Text.Json;

namespace ChatProjects.RealtimeService.Handlers;

public class ChatEventHandler
{
    private readonly IManagedMqttClient _mqttClient;
    private readonly ILogger<ChatEventHandler> _logger;

    public ChatEventHandler(IManagedMqttClient mqttClient, ILogger<ChatEventHandler> logger)
    {
        _mqttClient = mqttClient;
        _logger = logger;
    }

    // Wolverine 会自动调用这个 Handle 方法
    public async Task Handle(MessageSent @event)
    {
        _logger.LogInformation("收到消息事件，准备推送到 MQTT. MsgId: {Id}, ConvId: {ConvId}", @event.MessageId, @event.ConversationId);

        // 1. 构建 MQTT Topic
        // 策略：推送到 "chats/{ConversationId}/messages"
        // 这样所有订阅了这个会话的用户都能收到（包括发送者自己，用于多端同步）
        var topic = $"chats/{@event.ConversationId}/messages";

        // 2. 构建 Payload (与前端 ChatMessageEvent.fromJson 对应)
        var payloadObj = new
        {
            senderId = @event.SenderId,
            text = @event.Content,
            sentAt = @event.SentAt.ToString("O"), // ISO 8601 时间格式
            messageId = @event.MessageId,
            conversationId = @event.ConversationId
        };

        var payloadJson = JsonSerializer.Serialize(payloadObj);

        // 3. 发布到 MQTT
        var message = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(payloadJson)
            .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
            .WithRetainFlag(false)
            .Build();

        await _mqttClient.EnqueueAsync(message);

        _logger.LogInformation("已推送到 Topic: {Topic}", topic);
    }
}