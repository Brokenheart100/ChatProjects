
using ChatProjects.SearchService.Data;
using ChatProjects.SearchService.Services;
using Typesense.Setup;
using Wolverine;
using Wolverine.RabbitMQ;


var builder = WebApplication.CreateBuilder(args);

            builder.AddServiceDefaults();


// 1. 配置 Typesense 客户端
// Aspire 会注入 "services__typesense__http__0" 或者是我们在 AppHost 里显式配置的环境变量
            var typesenseApiKey = builder.Configuration["Typesense:ApiKey"] ?? "xyz";
// 如果 Aspire 服务发现不可用，回退到 localhost
            var typesenseUrl = builder.Configuration.GetConnectionString("typesense") ?? "http://localhost:8108";

            builder.Services.AddTypesenseClient(config =>
            {
                config.ApiKey = typesenseApiKey;
                var uri = new Uri(typesenseUrl);
                config.Nodes = new List<Node> { new Node(uri.Host, uri.Port.ToString(), "http") };
            });


            builder.Services.AddSingleton<SchemaInitializer>();
            builder.Services.AddHostedService<SchemaInitBackgroundService>();

            builder.Host.UseWolverine(opts =>
            {
                // 连接到名为 "messaging" 的 RabbitMQ 资源
                opts.UseRabbitMqUsingNamedConnection("messaging")
                    .AutoProvision();

                opts.ListenToRabbitQueue("search-service-queue", q =>
                {
                    q.BindExchange("chat-events"); // 将队列绑定到上面声明的交换机
                    q.IsDurable = true;
                    q.IsExclusive = false;
                });

            });


// 将 InMemoryDataStore 注册为单例，这样在整个应用生命周期中数据只会被创建一次
builder.Services.AddSingleton<InMemoryDataStore>();
            builder.AddNpgsqlDbContext<UserDbContext>("userdb");
            builder.Services.AddControllers();
            builder.Services.AddOpenApi();

            var app = builder.Build();
            app.MapDefaultEndpoints();
            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            //app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();

