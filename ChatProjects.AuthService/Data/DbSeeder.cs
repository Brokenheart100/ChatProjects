// ChatProjects.AuthService/Data/DbSeeder.cs

using ChatProjects.AuthService.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.AuthService.Data;

public static class DbSeeder
{
    // 这是一个扩展方法，方便在 Program.cs 中调用
    public static async Task SeedDatabaseAsync(this IApplicationBuilder app)
    {
        // 创建一个新的依赖注入作用域，以安全地获取所需的服务
        using var scope = app.ApplicationServices.CreateScope();
        var services = scope.ServiceProvider;

        var logger = services.GetRequiredService<ILogger<Program>>(); // 获取日志服务
        var userManager = services.GetRequiredService<UserManager<AppUser>>(); // 获取用户管理器

        try
        {
            logger.LogInformation("Attempting to seed database...");

            // 检查数据库中是否已经有任何用户
            if (await userManager.Users.AnyAsync())
            {
                logger.LogInformation("Database already has users. Seeding skipped.");
                return; // 如果已经有用户，则不执行任何操作
            }

            logger.LogInformation("No users found. Seeding new users...");

            // 创建一个包含10个用户的列表
            for (int i = 1; i <= 10; i++)
            {
                var user = new AppUser
                {
                    UserName = $"user{i}",
                    Email = $"user{i}@example.com",
                    EmailConfirmed = true, // 在开发环境中，我们可以默认邮箱已验证
                    DisplayName = $"测试用户{i}" // 填充我们自定义的字段
                };

                // 使用 UserManager 创建用户，它会自动处理密码哈希
                var result = await userManager.CreateAsync(user, $"Password{i}!");

                if (result.Succeeded)
                {
                    logger.LogInformation("Successfully created user: {UserName}", user.UserName);
                }
                else
                {
                    // 如果创建失败，记录错误
                    logger.LogWarning("Failed to create user {UserName}. Errors: {Errors}",
                        user.UserName, string.Join(", ", result.Errors.Select(e => e.Description)));
                }
            }

            logger.LogInformation("Database seeding completed.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred while seeding the database.");
        }
    }
}