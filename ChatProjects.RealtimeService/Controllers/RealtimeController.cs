using ChatProjects.RealtimeService.Services;
using Microsoft.AspNetCore.Mvc;
using MQTTnet;
using System.Text.Json;

namespace ChatProjects.RealtimeService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RealtimeController : ControllerBase
{
    private readonly MqttBrokerConnection _mqttConnection;
    private readonly ILogger<RealtimeController> _logger;

    public RealtimeController(MqttBrokerConnection mqttConnection, ILogger<RealtimeController> logger)
    {
        _mqttConnection = mqttConnection;
        _logger = logger;
    }

    /// <summary>
    /// 一个内部 API，供其他后端服务调用，以向特定用户推送通知。
    /// </summary>
    [HttpPost("push/user/{userId}")]
    public async Task<IActionResult> PushToUser(string userId, [FromBody] PushNotification notification)
    {
        // 定义一个专门给该用户推送通知的 Topic
        var topic = $"users/{userId}/notifications";

        var jsonPayload = JsonSerializer.Serialize(notification);
        var message = new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(jsonPayload)
            .WithQualityOfServiceLevel(MQTTnet.Protocol.MqttQualityOfServiceLevel.AtLeastOnce)
            .Build();

        await _mqttConnection.MqttClient.EnqueueAsync(message);

        _logger.LogInformation("Pushed notification of type '{Type}' to user {UserId}", notification.Type, userId);

        return Ok();
    }
}

// 一个通用的通知数据模型
public record PushNotification(string Type, object Data);