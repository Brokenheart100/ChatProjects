var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");

// ���һ����Ϊ "postgres-db" �� PostgreSQL ������������Դ��
var postgresServer = builder.AddPostgres("postgres-db");

// ������ݿ���Դ���Ա���Ҫ�洢�û�����ݺ��罻��ϵ�ķ������á�
var userDb = postgresServer.AddDatabase("userdb");

// ���һ����Ϊ "mongo-db" �� MongoDB ������������Դ��
var mongoServer = builder.AddMongoDB("mongo-db");

// ������ݿ���Դ���������¼�洢�������á�
var chatHistoryDb = mongoServer.AddDatabase("chathistorydb");

var userService = builder.AddProject<Projects.ChatProjects_UserService>("userservice")
    .WithReference(userDb);
var authService = builder.AddProject<Projects.ChatProjects_AuthService>("authservice")
    .WithReference(userDb);

builder.AddProject<Projects.ChatProjects_GatewayService>("gatewayservice")
    .WithReference(authService)
    .WithReference(userService);



builder.Build().Run();
