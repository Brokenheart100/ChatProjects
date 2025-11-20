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

builder.Services.AddSingleton<MqttBrokerConnection>();

// 1.手动创建和注入 IManagedMqttClient（替代 AddManagedMqttClient）
builder.Services.AddSingleton<IManagedMqttClient>(sp =>
{
    var logger = sp.GetRequiredService<ILogger<IManagedMqttClient>>();
    var loggerFactory = sp.GetRequiredService<ILoggerFactory>();  // 改用 LoggerFactory
                                                                  // 从 Aspire 配置读取 mqtt-broker 信息（自动注入）
    var mqttHost = builder.Configuration["services:mqtt-broker:endpoints:mqtt:host"] ?? "mqtt-broker";
    var mqttPort = int.Parse(builder.Configuration["services:mqtt-broker:endpoints:mqtt:port"] ?? "1883");

// 构建 ClientOptions
    var clientOptions = new MqttClientOptionsBuilder()
        .WithTcpServer(mqttHost, mqttPort)
        .WithClientId($"realtimeservice-{Environment.MachineName}-{Guid.NewGuid():N}")
        .WithCleanSession(false)
        //.WithCredentials("username", "password")  // 如果 EMQX 需要认证；否则移除
        .WithTls(new MqttClientOptionsBuilderTlsParameters { UseTls = false })  // 开发关闭 TLS
        .Build();

// 构建 ManagedOptions
    var managedOptions = new ManagedMqttClientOptionsBuilder()
        .WithClientOptions(clientOptions)
        .WithAutoReconnectDelay(TimeSpan.FromSeconds(5))
        .WithMaxPendingMessages(1000)
        .WithPendingMessagesOverflowStrategy(MqttPendingMessagesOverflowStrategy.DropOldestQueuedMessage)
        .Build();

// 创建 Managed Client
    var factory = new MqttFactory();
    var managedClient = factory.CreateManagedMqttClient();

// 启动（同步启动，避免 ArgumentNullException）
    managedClient.StartAsync(managedOptions).GetAwaiter().GetResult();

    return managedClient;
});

// 2. 注册您的 MqttBrokerConnection（现在能注入 IManagedMqttClient）
builder.Services.AddSingleton<MqttBrokerConnection>();
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
        q.BindExchange("user-events"); // 将队列绑定到上面声明的交换机
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
