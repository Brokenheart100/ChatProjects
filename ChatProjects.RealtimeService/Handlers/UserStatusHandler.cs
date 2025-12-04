using ChatProjects.Contracts.Events;
using MQTTnet;
using MQTTnet.Extensions.ManagedClient;
using System.Text.Json;

namespace ChatProjects.RealtimeService.Handlers;

public class UserStatusHandler(
    IManagedMqttClient mqttClient,
    ILogger<UserStatusHandler> logger)
{
    public async Task Handle(UserStatusChangedEvent @event)
    {
        logger.LogInformation("⚡ [StatusHandler] 处理状态变更: {User} -> {Status}", @event.UserId, @event.Status);

        // 构造推给前端的 JSON
        var payloadObj = new
        {
            userId = @event.UserId,
            status = @event.Status
        };
        var payloadJson = JsonSerializer.Serialize(payloadObj);

        // 循环给每个好友发消息
        foreach (var friendId in @event.FriendIds)
        {
            // 推送到好友订阅的 status 频道
            var topic = $"users/{friendId}/status";

            var message = new MqttApplicationMessageBuilder()
                .WithTopic(topic)
                .WithPayload(payloadJson)
                .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
                .Build();

            await mqttClient.EnqueueAsync(message);
        }

        logger.LogInformation("✅ [StatusHandler] 已推送给 {Count} 位好友", @event.FriendIds.Count);
    }
}