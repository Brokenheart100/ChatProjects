using ChatProjects.Contracts.Events;
using ChatProjects.UserService.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using ChatProjects.UserService.Services;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);


builder.AddServiceDefaults();
builder.AddNpgsqlDbContext<UserDbContext>("userdb");
builder.AddRedisClient("cache");

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["SecretKey"];

builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options => // ���� "Bearer" �����ľ�����֤����
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey!))
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Host.UseWolverine(opts =>
{
    // 1. 配置 RabbitMQ 连接
    opts.UseRabbitMqUsingNamedConnection("messaging")
        .AutoProvision(); // 启用自动创建拓扑

    // 2. 声明一个名为 "user-events" 的 Fanout 交换机
    opts.PublishMessage<UserRegistered>().ToRabbitExchange("user-events", e => e.ExchangeType = ExchangeType.Fanout);
    opts.PublishMessage<UserStatusChangedEvent>().ToRabbitExchange("chat-events");

    // 3. 监听一个队列，并将它绑定到交换机
    opts.ListenToRabbitQueue("userservice-inbox", q =>
    {
        q.BindExchange("user-events"); // 将队列绑定到上面声明的交换机
        q.IsDurable = true;
        q.IsExclusive = false;
    });

    // ---------------------------------------------------
});

builder.Services.AddHttpClient<RealtimeServiceApiClient>(client =>
{
    client.BaseAddress = new Uri("http://realtimeservice");
});


var app = builder.Build();

await ApplyDatabaseMigrations(app.Services);

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();


app.Run();
async Task ApplyDatabaseMigrations(IServiceProvider services)
{
    // 创建一个新的依赖注入作用域，以安全地获取服务
    using var scope = services.CreateScope();
    var serviceProvider = scope.ServiceProvider;
    // 获取日志记录器，以便我们能看到发生了什么
    var logger = serviceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        logger.LogInformation("Attempting to apply database migrations for UserDbContext...");

        // 获取数据库上下文实例
        var context = serviceProvider.GetRequiredService<UserDbContext>();

        // 核心操作：异步地应用所有待处理的迁移
        await context.Database.MigrateAsync();

        logger.LogInformation("Database migrations applied successfully.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while applying database migrations.");
        // 在开发环境中，让应用崩溃是一个好主意，因为它能立刻暴露数据库问题
        throw;
    }
}