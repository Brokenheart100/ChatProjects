var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

var postgresServer = builder.AddPostgres("postgres-db")
    .WithHttpEndpoint(1234,1234,name: "postgresServer")
    .WithPgAdmin()
    .WithDataVolume("postgres_data");

var userdb = postgresServer.AddDatabase("userdb");

var mongoServer = builder.AddMongoDB("mongo-db");

var chatHistoryDb = mongoServer.AddDatabase("chathistorydb");

var userService = builder.AddProject<Projects.ChatProjects_UserService>("userservice")
    .WithReference(userdb);

var authService = builder.AddProject<Projects.ChatProjects_AuthService>("authservice")
    .WithReference(userdb);

builder.AddProject<Projects.ChatProjects_GatewayService>("gatewayservice")
    .WithReference(authService)
    .WithReference(userService);



builder.Build().Run();


