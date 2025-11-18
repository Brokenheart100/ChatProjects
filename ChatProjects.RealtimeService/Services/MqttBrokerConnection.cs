using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Extensions.ManagedClient;

namespace ChatProjects.RealtimeService.Services;

public class MqttBrokerConnection(
    IManagedMqttClient managedClient,
    ILogger<MqttBrokerConnection> logger) : IHostedService
{
    public IManagedMqttClient MqttClient => managedClient;

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        logger.LogInformation("MQTT Managed Client is starting... (configured by Aspire)");

        // 这里不需要再 StartAsync，由 AddManagedMqttClient 自动管理
        // 您可以在这里订阅一些系统级 Topic
        managedClient.ApplicationMessageReceivedAsync += async e =>
        {
            logger.LogInformation("Received message on topic: {Topic}", e.ApplicationMessage.Topic);
            await Task.CompletedTask;
        };

        await Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
