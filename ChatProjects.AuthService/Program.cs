using ChatProjects.AuthService.Data;
using ChatProjects.AuthService.Extensions;
using ChatProjects.AuthService.Services;
using ChatProjects.Contracts.Events;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

// --- 1. ע����� ---

builder.AddServiceDefaults();
builder.AddNpgsqlDbContext<AuthDbContext>("userdb");



// ʹ�����Ǵ�������չ������ע�� Identity ��صķ���
builder.Services.AddIdentityServices(builder.Configuration);

// ע�������Զ���� TokenService���Ա��� Controller ��ע��
builder.Services.AddScoped<TokenService>();

// **ע�� MVC ����������**
builder.Services.AddControllers();

// **��ӱ�׼�� Swagger/OpenAPI ���� (ֻ���һ��)**
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
//builder.Services.AddOpenTelemetry().WithTracing(TracerProviderBuilder =>
//            {
//                TracerProviderBuilder
//                .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(builder.Environment.ApplicationName))
//                .AddSource("Wolverine");

//            });
//builder.Host.UseWolverine(opts =>
//{
//    opts.UseRabbitMqUsingNamedConnection("messaging").AutoProvision();
//    opts.PublishAllMessages().ToRabbitExchange("file-exchange");
//});

builder.Host.UseWolverine(opts =>
{
    // 1. 使用 RabbitMQ 作为传输
    opts.UseRabbitMqUsingNamedConnection("messaging").AutoProvision();

    // 2. 将所有发布的消息路由到一个名为 "user-events" 的交换机
    //opts.PublishAllMessages().ToRabbitExchange("user-events");
    opts.PublishMessage<UserRegistered>().ToRabbitExchange("user-events", e => e.ExchangeType = ExchangeType.Fanout);
});

// --- 2. ����Ӧ�ó��� ---
var app = builder.Build();


// --- 3. ���� HTTP ������ܵ� (�м��) ---

// ӳ�� Aspire �Ľ�������Ĭ�϶˵�
app.MapDefaultEndpoints();

// ֻ�ڿ������������ñ�׼�� Swagger UI �м��
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseRouting();

app.Use(async (context, next) =>
{
    // 记录所有进入管道但最终可能未匹配的请求
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    logger.LogWarning("Incoming request: {Method} {Path}", context.Request.Method, context.Request.Path);

    // 如果端点仍为空，说明没有路由匹配
    if (context.GetEndpoint() == null)
    {
        logger.LogError("No endpoint found for {Method} {Path}", context.Request.Method, context.Request.Path);
    }
    await next(context);
});


app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

await ApplyMigrationsAsync(app.Services);
app.MapControllers();
app.Run();



async Task ApplyMigrationsAsync(IServiceProvider services)
{
    // ����һ���µ�����ע���������԰�ȫ�ػ�ȡ����
    using var scope = services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    try
    {
        logger.LogInformation("Attempting to apply database migrations...");

        // �첽��Ӧ�����й����Ǩ��
        await dbContext.Database.MigrateAsync();

        logger.LogInformation("Database migrations applied successfully.");
        // 4.2 ִ���������
        //await app.SeedDatabaseAsync();
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while applying database migrations.");
        // �����������У�������ϣ����������Ӹ���׳�Ĵ������
        // ���������߼�����Ǩ��ʧ��ʱֱ����Ӧ��ֹͣ�����
    }
}