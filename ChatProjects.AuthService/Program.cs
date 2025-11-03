using ChatProjects.AuthService.Data;
using ChatProjects.AuthService.Extensions;
using ChatProjects.AuthService.Services;
using Microsoft.AspNetCore.Identity;

namespace ChatProjects.AuthService
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // --- 1. Aspire 和数据库配置 ---
             builder.AddServiceDefaults(); // 添加 Aspire 默认配置 (遥测, 健康检查等)
            // 
            // // 添加并配置 AuthDbContext，"userdb" 对应 AppHost 和 appsettings.json 中的名称
            // // Aspire 会自动处理连接字符串的注入
             builder.AddNpgsqlDbContext<AuthDbContext>("userdb");

             // 使用扩展方法注册 Identity 服务
             builder.Services.AddIdentityServices();

             // 注册我们自定义的 TokenService
             builder.Services.AddScoped<TokenService>();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            var app = builder.Build();
            app.MapDefaultEndpoints(); // 添加 Aspire 的健康检查等端点
            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
