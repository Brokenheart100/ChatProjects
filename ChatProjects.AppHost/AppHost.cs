using Aspire.Hosting;
using Microsoft.Extensions.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var rabbitmq = builder.AddRabbitMQ("messaging")
    .WithManagementPlugin()
    .WithDataVolume("rabbitmq_data");

var emqxAdminUser = builder.AddParameter("emqx-admin-user");
var emqxAdminPassword = builder.AddParameter("emqx-admin-password", secret: true);

var mqttBroker = builder.AddContainer("mqtt-broker", "emqx/emqx:latest")
    .WithHttpEndpoint(port: 18083, targetPort: 18083, name: "emqx-dashboard")
    .WithEndpoint(port: 1883, targetPort: 1883, name: "mqtt")
    .WithEnvironment("EMQX_ADMIN_USER", emqxAdminUser)
    .WithEnvironment("EMQX_ADMIN_PASSWORD", emqxAdminPassword);

var postgresServer = builder.AddPostgres("postgres-db")
    .WithEndpoint(1234, 1234, name: "postgresServer",isExternal:true)
    .WithPgAdmin()
    .WithDataVolume("postgres_data");


var typesense = builder.AddContainer("typesense", "typesense/typesense","29.0")  // 服务名、镜像、版本
    .WithArgs("--data-dir", "/data", "--api-key", "xyz", "--enable-cors")  // 启动参数（数据目录、API密钥、启用CORS）
    .WithVolume("typesense-data", "/data")  // 挂载数据卷持久化索引数据
    .WithHttpEndpoint(8108, 8108, name: "typesense");  // 暴露8108端口（内部/外部一致）

var typesenseContainer = typesense.GetEndpoint("typesense");

 
// 1. 定义 MinIO 的访问凭证 (可以放在 User Secrets 中)
var minioAccessKey = builder.AddParameter("minioaccesskey", secret: true);
var minioSecretKey = builder.AddParameter("miniosecretkey", secret: true);
var minioEndpoint = "localhost:9000"; // 我们直接用字符串，或者从参数获取
var minioBucket = "avatars"; // Bucket 名称

// 2. 添加 MinIO 容器资源
var minio = builder.AddContainer("minio", "minio/minio", "latest")
    .WithArgs("server", "/data", "--console-address", ":9090") // 保持最核心的启动命令
    .WithVolume("minio_data", "/data")
    .WithHttpEndpoint(9090, 9090, "console")
    .WithHttpEndpoint(9000,9000,"s3")
    .WithEnvironment("MINIO_ROOT_USER", minioAccessKey)
    .WithEnvironment("MINIO_ROOT_PASSWORD", minioSecretKey);


var userdb = postgresServer.AddDatabase("userdb");


var orleansStorage = builder.AddRedis("orleansStorage");

// 2. 添加 Orleans Silo 项目
var orleansSilo = builder.AddProject<Projects.ChatProjects_OrleansSilo>("orleans-silo")
    .WithReference(orleansStorage); // 告诉 Silo 使用这个存储
    
// 3. 将 Orleans 集群添加到 Aspire 中
var orleans = builder.AddOrleans("my-orleans-cluster")
    .WithClustering(orleansStorage) // 告诉 Aspire，这个 Silo 是集群的一部分
    .WithGrainStorage("Default", orleansStorage); // 配置名为 "Default" 的 Grain 存储



var userService = builder.AddProject<Projects.ChatProjects_UserService>("userservice")
    .WithReference(rabbitmq)
    .WaitFor(rabbitmq)
    .WithReference(userdb);

var authService = builder.AddProject<Projects.ChatProjects_AuthService>("authservice")
    .WithReference(rabbitmq)
    .WaitFor(rabbitmq)
    .WithReference(userdb);

var fileService = builder.AddProject<Projects.ChatProjects_FileService>("fileservice")
    .WithEnvironment("Minio__Endpoint", minioEndpoint) // 注意这里是双下划线
    .WithEnvironment("Minio__AccessKey", minioAccessKey)
    .WithEnvironment("Minio__SecretKey", minioSecretKey)
    .WithEnvironment("Minio__BucketName", minioBucket);

var searchService = builder.AddProject<Projects.ChatProjects_SearchService>("searchservice")
    .WithReference(userdb); // 它需要访问用户数据库

var realtimeService = builder.AddProject<Projects.ChatProjects_RealtimeService>("realtimeservice")
    //.WithReference(mqttBroker)
    .WithEnvironment("ConnectionStrings__mqtt", mqttBroker.GetEndpoint("mqtt"))
    .WithReference(mqttBroker.GetEndpoint("mqtt"));




builder.AddProject<Projects.ChatProjects_GatewayService>("gatewayservice")
    .WithReference(rabbitmq)
    .WithReference(realtimeService)
    .WithReference(fileService)
    .WithReference(authService)
    .WithReference(searchService)
    .WithReference(userService);





builder.Build().Run();


