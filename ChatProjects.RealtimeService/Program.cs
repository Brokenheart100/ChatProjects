using ChatProjects.RealtimeService.Hubs;
using ChatProjects.RealtimeService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using MQTTnet;
using MQTTnet.Client;
using MQTTnet.Server;
using MQTTnet.Extensions.ManagedClient;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddHostedService<MqttBrokerConnection>();


builder.Services.AddSingleton<IManagedMqttClient>(sp =>
{
    var logger = sp.GetRequiredService<ILogger<IManagedMqttClient>>();
    var config = sp.GetRequiredService<IConfiguration>(); // 获取配置

    // === 核心修复：统一地址解析逻辑 ===
    string host = "localhost";
    int port = 1883;

    var connStr = config.GetConnectionString("mqtt");
    if (!string.IsNullOrEmpty(connStr))
    {
        var uri = new Uri(connStr);
        host = uri.Host;
        port = uri.Port;
    }
    else
    {
        var h = config["services:mqtt-broker:endpoints:mqtt:host"];
        if (!string.IsNullOrEmpty(h)) host = h;
        if (int.TryParse(config["services:mqtt-broker:endpoints:mqtt:port"], out var p)) port = p;
    }
    // =================================

    var clientOptions = new MqttClientOptionsBuilder()
        .WithTcpServer(host, port)
        .WithClientId($"realtime-init-{Guid.NewGuid()}")
        .WithCleanSession(false)
        .WithTls(new MqttClientOptionsBuilderTlsParameters { UseTls = false })
        .Build();

    var managedOptions = new ManagedMqttClientOptionsBuilder()
        .WithClientOptions(clientOptions)
        .WithAutoReconnectDelay(TimeSpan.FromSeconds(5))
        .Build();

    var factory = new MqttFactory();
    var managedClient = factory.CreateManagedMqttClient();

    // 异步启动，不阻塞
    //_ = managedClient.StartAsync(managedOptions);

    return managedClient;
});
// 2. 注册您的 MqttBrokerConnection（现在能注入 IManagedMqttClient）
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // ... (您的 TokenValidationParameters 配置)

        // 关键：让 SignalR 能够从 QueryString 中读取 Token
        // 因为 WebSocket 连接在建立时无法像普通 HTTP 请求一样设置 Authorization 头
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(accessToken))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddControllers();
builder.Services.AddOpenApi();

builder.Host.UseWolverine(opts =>
{
    // 连接到 AppHost 定义的 "messaging" RabbitMQ
    opts.UseRabbitMqUsingNamedConnection("messaging")
        .AutoProvision();

    opts.ListenToRabbitQueue("realtime-service-queue", q =>
    {
        q.BindExchange("chat-events"); // 将队列绑定到上面声明的交换机
    });
  
});

var app = builder.Build();

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
