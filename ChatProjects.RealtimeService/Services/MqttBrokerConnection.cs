using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Extensions.ManagedClient;
using System.Text.Json.Nodes;

namespace ChatProjects.RealtimeService.Services;

public class MqttBrokerConnection : IHostedService
{
    private readonly IManagedMqttClient _managedClient;
    private readonly ILogger<MqttBrokerConnection> _logger;
    private readonly IConfiguration _configuration;
    private readonly UserStatusService _statusService;

    // ✅ 必须暴露给 Controller 使用
    public IManagedMqttClient MqttClient => _managedClient;

    public MqttBrokerConnection(
        IManagedMqttClient managedClient,
        ILogger<MqttBrokerConnection> logger,
        IConfiguration configuration,
        UserStatusService statusService)
    {
        _managedClient = managedClient;
        _logger = logger;
        _configuration = configuration;
        _statusService = statusService;
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

        _managedClient.ConnectedAsync += OnConnectedAsync;
        _managedClient.DisconnectedAsync += OnDisconnectedAsync;
        _managedClient.ConnectingFailedAsync += OnConnectingFailedAsync;
        _managedClient.ApplicationMessageReceivedAsync += OnMessageReceivedAsync;

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
    private async Task OnConnectedAsync(MqttClientConnectedEventArgs arg)
    {
        _logger.LogInformation("✅ [MqttConnection] 成功连接到 EMQX Broker!");

        // 5. 订阅系统主题 (监听用户上下线)
        // EMQX 的系统主题格式：$SYS/brokers/{node}/clients/{clientid}/connected
        // 使用通配符 + 订阅所有节点的客户端事件
        await _managedClient.SubscribeAsync("$SYS/brokers/+/clients/+/connected");
        await _managedClient.SubscribeAsync("$SYS/brokers/+/clients/+/disconnected");

        _logger.LogInformation("📡 [MqttConnection] 已订阅系统上下线通知 ($SYS)");
    }

    private Task OnDisconnectedAsync(MqttClientDisconnectedEventArgs arg)
    {
        _logger.LogWarning("⚠️ [MqttConnection] 连接断开: {Reason}", arg.Reason);
        return Task.CompletedTask;
    }

    private Task OnConnectingFailedAsync(ConnectingFailedEventArgs arg)
    {
        _logger.LogError("❌ [MqttConnection] 连接尝试失败: {Msg}", arg.Exception.Message);
        return Task.CompletedTask;
    }

    /// <summary>
    /// 处理收到的所有 MQTT 消息 (核心逻辑)
    /// </summary>
    private async Task OnMessageReceivedAsync(MqttApplicationMessageReceivedEventArgs arg)
    {
        var topic = arg.ApplicationMessage.Topic;

        // 只处理系统消息
        if (topic.StartsWith("$SYS"))
        {
            await HandleSysEvent(arg.ApplicationMessage);
        }
    }

    /// <summary>
    /// 解析系统事件并更新 Redis 状态
    /// </summary>
    private async Task HandleSysEvent(MqttApplicationMessage msg)
    {
        try
        {
            var payload = msg.ConvertPayloadToString();
            var json = JsonNode.Parse(payload);

            // 1. 解析 ClientID
            // 假设前端格式为: flutter_client_{UserId}
            var clientId = json?["clientid"]?.ToString();

            if (string.IsNullOrEmpty(clientId) || !clientId.StartsWith("flutter_client_"))
            {
                // 忽略非前端用户的连接 (比如 backend-service 自己的连接)
                return;
            }

            // 提取 UserId
            var userId = clientId.Replace("flutter_client_", "");

            // 2. 判断事件类型
            bool isStatusChanged = false;
            bool isOnline = false;

            if (msg.Topic.EndsWith("/connected"))
            {
                // 设备上线 -> 存入 Redis
                // DeviceConnectedAsync 返回 true 表示该用户从“离线”变成了“在线”（第一个设备）
                isStatusChanged = await _statusService.DeviceConnectedAsync(userId, clientId);
                isOnline = true;
                _logger.LogInformation("🔌 [SysEvent] 设备上线: {UserId} (Client: {ClientId})", userId, clientId);
            }
            else if (msg.Topic.EndsWith("/disconnected"))
            {
                // 设备下线 -> 从 Redis 移除
                // DeviceDisconnectedAsync 返回 true 表示该用户从“在线”变成了“离线”（最后一个设备）
                isStatusChanged = await _statusService.DeviceDisconnectedAsync(userId, clientId);
                isOnline = false;
                _logger.LogInformation("🔌 [SysEvent] 设备下线: {UserId} (Client: {ClientId})", userId, clientId);
            }

            // 3. 如果状态发生了实质变化 (0->1 或 1->0)，触发广播
            if (isStatusChanged)
            {
                await BroadcastUserStatus(userId, isOnline);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "🔥 [SysEvent] 解析系统消息失败");
        }
    }
    /// <summary>
    /// 广播用户状态变更 (通知好友)
    /// </summary>
    private async Task BroadcastUserStatus(string userId, bool isOnline)
    {
        // 在微服务架构中，这里最标准的做法是：
        // 发送一个 UserStatusChangedEvent 到 RabbitMQ -> UserService 消费 -> 查好友 -> 发回 RealtimeService 推送

        // 但为了简单和性能，我们也可以在这里直接做。
        // 不过 RealtimeService 通常不连 UserDB，所以我们只打日志，或者你可以注入 HttpClient 调用 UserService 获取好友列表

        _logger.LogInformation("🔔 [StatusBroadcast] 用户 {User} 状态变为 {Status}，应触发广播", userId, isOnline ? "在线" : "离线");

        // TODO: 如果你想在这里直接发通知，你需要知道他的好友是谁。
        // 建议：这里只负责维护 Redis 状态。
        // 实际的“通知好友”逻辑，最好还是通过 RabbitMQ 发事件给 UserService 处理，
        // 或者前端轮询/按需拉取状态。
    }
    public async Task StopAsync(CancellationToken cancellationToken)
    {
        await _managedClient.StopAsync();
    }
}