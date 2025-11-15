using ChatProjects.AuthService.Data;
using ChatProjects.AuthService.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

namespace ChatProjects.AuthService.Extensions;

public static class IdentityServiceExtensions
{
    // 方法签名保持不变
    public static IServiceCollection AddIdentityServices(this IServiceCollection services, IConfiguration config)
    {
        // --- 1. Identity Core 配置 ---
        // 配置 Identity 框架，指定用户和角色的类型，以及存储提供者
        services.AddIdentity<AppUser, IdentityRole>(options =>
        {
            // 在开发环境中，我们可以放宽密码策略以方便测试
            options.Password.RequireDigit = false;
            options.Password.RequireLowercase = false;
            options.Password.RequireUppercase = false;
            options.Password.RequireNonAlphanumeric = false;
            options.Password.RequiredLength = 1;
        })
        .AddEntityFrameworkStores<AuthDbContext>()
        .AddDefaultTokenProviders();

        // --- 2. JWT Bearer 认证配置 ---
        // 从 appsettings.json 或环境变量中读取 JWT 相关配置
        var jwtSettings = config.GetSection("Jwt");
        var secretKey = jwtSettings["SecretKey"];

        if (string.IsNullOrEmpty(secretKey))
        {
            // 在启动时就进行检查，如果 SecretKey 未配置，则直接抛出异常
            // 避免在运行时才发现配置错误
            throw new ArgumentNullException(nameof(secretKey), "JWT SecretKey must be configured.");
        }

        // 添加认证服务，并配置默认的认证方案
        services.AddAuthentication(options =>
        {
            // 当需要对用户进行身份验证时，默认使用 JWT Bearer 方案
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            // 当未经身份验证的用户尝试访问受保护资源时，默认也使用 JWT Bearer 方案来“挑战”他们
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options => // 配置 JWT Bearer 方案的具体细节
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                // -- 必须验证的项 --
                ValidateIssuerSigningKey = true, // 必须验证签名密钥
                ValidateIssuer = true,           // 必须验证令牌的签发者
                ValidateAudience = true,         // 必须验证令牌的接收者
                ValidateLifetime = true,         // 必须验证令牌的有效期

                // -- 配置有效值 --
                ValidIssuer = jwtSettings["Issuer"],
                ValidAudience = jwtSettings["Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),

                // (可选) 允许服务器时间和客户端时间有小的偏差
                ClockSkew = TimeSpan.Zero // 通常设为 Zero，要求时间绝对精确
            };
        });

        // --- 3. 覆盖 Identity 默认重定向行为 (核心修复) ---
        // 这个配置可以防止 Identity 在 API 场景下返回 302 重定向到登录页
        services.ConfigureApplicationCookie(options =>
        {
            options.Events.OnRedirectToLogin = context =>
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                return Task.CompletedTask;
            };
            options.Events.OnRedirectToAccessDenied = context =>
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                return Task.CompletedTask;
            };
        });

        // 返回 services 以支持链式调用
        return services;
    }
}