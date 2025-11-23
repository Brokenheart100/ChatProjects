using ChatProjects.ChatHistoryService.Data;
using ChatProjects.Contracts.Events;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;
using System.Text;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// 注册一个命名 HTTP Client，基地址指向 Aspire 中的 "userservice"
builder.Services.AddHttpClient("UserService", client =>
{
    // 注意：这里的 base address 必须和 AppHost 里的名字一致
    client.BaseAddress = new Uri("http://userservice");
});

builder.AddNpgsqlDbContext<ChatHistoryDbContext>("chathistorydb");


// 3. 配置 JWT 认证 (与 UserService/RealtimeService 保持一致)
var jwtSettings = builder.Configuration.GetSection("Jwt");
// 如果本地开发没有配置 Jwt Section，这里可能会报错，建议检查 appsettings.json 或 Aspire 注入
var secretKey = jwtSettings["SecretKey"] ?? "your_fallback_secret_key_for_dev_only_123456";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"] ?? "ChatApp",
            ValidAudience = jwtSettings["Audience"] ?? "ChatAppClient",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
        };
    });

builder.Services.AddAuthorization();

// 4. 配置 Wolverine (RabbitMQ)
builder.Host.UseWolverine(opts =>
{
    // 连接到 AppHost 定义的 "messaging" RabbitMQ
    opts.UseRabbitMqUsingNamedConnection("messaging")
        .AutoProvision();

    // 这里配置发布消息的规则，例如：
     opts.PublishMessage<MessageSent>().ToRabbitExchange("chat-events");
});


builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();
await ApplyDatabaseMigrations(app.Services);

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

//app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();



app.Run();

// --- 辅助方法：自动迁移数据库 ---
async Task ApplyDatabaseMigrations(IServiceProvider services)
{
    using var scope = services.CreateScope();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    var context = scope.ServiceProvider.GetRequiredService<ChatHistoryDbContext>();

    // 简单的重试机制，因为容器启动时数据库端口可能还没完全准备好
    var retries = 5;
    while (retries > 0)
    {
        try
        {
            logger.LogInformation("Attempting to apply ChatHistoryDbContext migrations...");

            // 【核心修复】直接调用 MigrateAsync，不要先调用 GetPendingMigrationsAsync
            // MigrateAsync 会自动创建数据库(如果不存在)并创建表
            await context.Database.MigrateAsync();

            logger.LogInformation("ChatHistoryDbContext migrations applied successfully.");
            break; // 成功则退出循环
        }
        catch (NpgsqlException ex)
        {
            // 捕获数据库连接错误（例如数据库正在启动中）
            logger.LogWarning(ex, "Database not ready yet. Retrying in 2 seconds... ({Retries} retries left)", retries);
            retries--;
            await Task.Delay(2000);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Critical error applying migrations.");
            throw; // 非网络/启动错误直接抛出
        }
    }
}