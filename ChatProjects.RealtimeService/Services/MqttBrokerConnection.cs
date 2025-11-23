using MQTTnet.Extensions.ManagedClient;
using MQTTnet.Client;
using MQTTnet;

namespace ChatProjects.RealtimeService.Services;

public class MqttBrokerConnection : IHostedService
{
    private readonly IManagedMqttClient _managedClient;
    private readonly ILogger<MqttBrokerConnection> _logger;
    private readonly IConfiguration _configuration;

    public IManagedMqttClient MqttClient => _managedClient;

    public MqttBrokerConnection(
        IManagedMqttClient managedClient,
        ILogger<MqttBrokerConnection> logger,
        IConfiguration configuration)
    {
        _managedClient = managedClient;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogWarning("============== [MQTT 深度调试] 开始启动 ==============");

        string host = "localhost"; // 默认值改为 localhost
        int port = 1883;

        // 1. 优先尝试读取 ConnectionString (这是 Aspire 最推荐的方式)
        // 格式通常是: tcp://localhost:54123
        var connStr = _configuration.GetConnectionString("mqtt");

        if (!string.IsNullOrEmpty(connStr))
        {
            try
            {
                var uri = new Uri(connStr);
                host = uri.Host;
                port = uri.Port;
                _logger.LogInformation("✅ [配置源] 使用 ConnectionString: {Str}", connStr);
            }
            catch
            {
                _logger.LogWarning("⚠️ ConnectionString 解析失败，尝试使用独立配置项");
            }
        }
        else
        {
            // 2. 尝试读取独立配置项
            var hostCfg = _configuration["services:mqtt-broker:endpoints:mqtt:host"];
            var portCfg = _configuration["services:mqtt-broker:endpoints:mqtt:port"];

            if (!string.IsNullOrEmpty(hostCfg)) host = hostCfg;
            if (int.TryParse(portCfg, out var p)) port = p;

            _logger.LogInformation("ℹ️ [配置源] 使用 Services 配置: {Host}:{Port}", hostCfg, portCfg);
        }

        _logger.LogInformation("🚀 [最终连接目标] Host: '{Host}', Port: '{Port}'", host, port);

        // 3. 构建连接选项
        var clientOptions = new MqttClientOptionsBuilder()
            .WithTcpServer(host, port)
            // 使用随机 ClientId 避免冲突
            .WithClientId($"backend-svc-{Guid.NewGuid().ToString()[..6]}")
            .WithTimeout(TimeSpan.FromSeconds(10))
            .WithKeepAlivePeriod(TimeSpan.FromSeconds(30))
            .Build();

        var managedOptions = new ManagedMqttClientOptionsBuilder()
            .WithClientOptions(clientOptions)
            .WithAutoReconnectDelay(TimeSpan.FromSeconds(3))
            .Build();

        try
        {
            _logger.LogInformation("⏳ 正在发起连接...");
            await _managedClient.StartAsync(managedOptions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ StartAsync 异常");
        }
    }

    public async Task StopAsync(CancellationToken cancellationToken)
    {
        await _managedClient.StopAsync();
    }
}