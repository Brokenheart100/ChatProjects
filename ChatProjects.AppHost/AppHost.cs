var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var postgresServer = builder.AddPostgres("postgres-db")
    .WithDataVolume()
    .WithPgAdmin()
    .WithEnvironment("POSTGRES_PASSWORD", "your_dev_password")
    .WithEndpoint("postgres", e =>
    {
        e.Port = 5433;       // Port 对应 hostPort
        e.TargetPort = 5432; // TargetPort 对应 containerPort
    });

var userDb = postgresServer.AddDatabase("userdb");


var mongoServer = builder.AddMongoDB("mongo-db");


var chatHistoryDb = mongoServer.AddDatabase("chathistorydb");

var userService = builder.AddProject<Projects.ChatProjects_UserService>("userservice")
    .WithReference(userDb);
var authService = builder.AddProject<Projects.ChatProjects_AuthService>("authservice")
    .WithReference(userDb);

builder.AddProject<Projects.ChatProjects_GatewayService>("gatewayservice")
    .WithReference(authService)
    .WithReference(userService);



builder.Build().Run();
