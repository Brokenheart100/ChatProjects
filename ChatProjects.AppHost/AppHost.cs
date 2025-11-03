var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var postgresServer = builder.AddPostgres("postgres-db");

var userDb = postgresServer.AddDatabase("userdb");

var mongoServer = builder.AddMongoDB("mongo-db");

var chatHistoryDb = mongoServer.AddDatabase("chathistorydb");

var userService = builder.AddProject<Projects.ChatProjects_UserService>("userservice")
    .WithReference(userDb);
var authService = builder.AddProject<Projects.ChatProjects_AuthService>("authservice1")
    .WithReference(userDb);

builder.AddProject<Projects.ChatProjects_GatewayService>("gatewayservice1")
    .WithReference(authService)
    .WithReference(userService);



builder.Build().Run();
