// 文件: ChatProjects.UserService/Handlers/UserEventHandler.cs
using ChatProjects.Contracts.Events;
using ChatProjects.UserService.Data;
using ChatProjects.UserService.Entities;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.UserService.Handlers;

public class UserEventHandler
{
    // Wolverine 会自动将事件消息和依赖的服务注入到 Consume 方法中
    public static async Task Consume(
        UserRegistered message,
        UserDbContext dbContext,
        ILogger<UserEventHandler> logger)
    {
        logger.LogInformation("Received UserRegistered event for UserId: {UserId}", message.UserId);

        // 检查该用户资料是否已经存在，以处理消息重复消费的情况 (幂等性)
        var userExists = await dbContext.UserProfiles.AnyAsync(u => u.UserId == message.UserId);
        if (userExists)
        {
            logger.LogWarning("User profile for UserId {UserId} already exists. Skipping creation.", message.UserId);
            return;
        }

        // 创建新的用户资料实体
        var newUserProfile = new UserProfile
        {
            UserId = message.UserId,
            UserName = message.UserName,
            DisplayName = message.UserName // 默认将用户名作为昵称
        };

        dbContext.UserProfiles.Add(newUserProfile);
        await dbContext.SaveChangesAsync();

        logger.LogInformation("Successfully created user profile for UserId: {UserId}", message.UserId);
    }
}