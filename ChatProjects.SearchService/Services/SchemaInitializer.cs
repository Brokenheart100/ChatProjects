using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection; // 引入此命名空间
using Typesense;

namespace ChatProjects.SearchService.Services;

public class SchemaInitializer
{
    // 移除直接注入的 ITypesenseClient
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SchemaInitializer> _logger;

    // 修改构造函数，注入 ScopeFactory
    public SchemaInitializer(IServiceScopeFactory scopeFactory, ILogger<SchemaInitializer> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public async Task EnsureSchemaAsync()
    {
        var collectionName = "messages";

        // ✅ 关键修改：创建一个新的作用域来获取 TypesenseClient
        using var scope = _scopeFactory.CreateScope();
        var client = scope.ServiceProvider.GetRequiredService<ITypesenseClient>();

        try
        {
            // 使用从 scope 中获取的 client
            await client.RetrieveCollection(collectionName);
            _logger.LogInformation("✅ [Typesense] Collection '{Name}' exists.", collectionName);
        }
        catch (TypesenseApiNotFoundException)
        {
            _logger.LogInformation("🛠️ [Typesense] Creating collection '{Name}'...", collectionName);

            var schema = new Schema(
                collectionName,
                new List<Field>
                {
                    new Field("id", FieldType.String),
                    new Field("conversation_id", FieldType.String, facet: true),
                    new Field("sender_id", FieldType.String),
                    new Field("content", FieldType.String),
                    new Field("sent_at", FieldType.Int64)
                },
                "sent_at"
            );

            await client.CreateCollection(schema);
            _logger.LogInformation("✅ [Typesense] Collection '{Name}' created successfully.", collectionName);
        }
        catch (Exception ex)
        {
            // 捕获其他异常，防止导致应用启动崩溃
            _logger.LogError(ex, "❌ [Typesense] Failed to initialize schema.");
            throw;
        }
    }
}

public class SchemaInitBackgroundService : BackgroundService
{
    private readonly SchemaInitializer _initializer;
    private readonly ILogger<SchemaInitBackgroundService> _logger;

    public SchemaInitBackgroundService(
        SchemaInitializer initializer,
        ILogger<SchemaInitBackgroundService> logger)
    {
        _initializer = initializer;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // 定义最大重试次数（防止死循环）
        int retryCount = 0;
        const int maxRetries = 10;

        while (!stoppingToken.IsCancellationRequested && retryCount < maxRetries)
        {
            try
            {
                _logger.LogInformation("🔄 [Typesense] Attempting to connect and initialize schema (Attempt {Count}/{Max})...", retryCount + 1, maxRetries);

                await _initializer.EnsureSchemaAsync();

                _logger.LogInformation("✅ [Typesense] Schema initialization completed.");
                return; // 成功后直接退出后台任务
            }
            catch (Exception ex) when (ex is TaskCanceledException || ex is HttpRequestException || ex is TimeoutException)
            {
                // 捕获网络相关的异常（超时、连接拒绝）
                retryCount++;
                _logger.LogWarning("⚠️ [Typesense] Not ready yet. Retrying in 3 seconds... Error: {Message}", ex.Message);

                try
                {
                    // 等待 3 秒再重试
                    await Task.Delay(3000, stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    // 如果在等待期间应用关闭了，直接退出
                    break;
                }
            }
            catch (Exception ex)
            {
                // 其他未知的严重错误，记录并不再重试
                _logger.LogError(ex, "❌ [Typesense] Critical error during schema initialization.");
                break;
            }
        }

        if (retryCount >= maxRetries)
        {
            _logger.LogError("❌ [Typesense] Failed to connect after {Max} attempts. Search functionality may not work.", maxRetries);
        }
    }
}