using ChatProjects.UserService.Entities;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.UserService.Data;

public class UserDbContext : DbContext
{
    public UserDbContext(DbContextOptions<UserDbContext> options) : base(options)
    {
    }
    // public DbSet<UserProfile> Users { get; set; }
    public DbSet<UserProfile> UserProfiles { get; set; }
    public DbSet<FriendRequest> FriendRequests { get; set; }
    public DbSet<Friendship> Friendships { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        //modelBuilder.Entity<UserProfile>().ToTable("AspNetUsers", schema: "public");
        modelBuilder.Entity<UserProfile>(entity =>
        {
            entity.HasKey(e => e.Id); // 将 UserId 设为主键
            entity.ToTable("UserProfiles");
        });

        // (可选但推荐) 在这里为 FriendRequest 配置主键等
        modelBuilder.Entity<FriendRequest>(entity =>
        {
            entity.HasKey(e => e.Id);
            // 可以添加索引等其他配置
            entity.HasIndex(e => new { e.SenderId, e.RecipientId }).IsUnique();
            entity.Property(e => e.Status)
                .HasConversion<string>();
        });
        modelBuilder.Entity<Friendship>(entity =>
     {
         entity.HasKey(e => e.Id);
         // 创建一个复合唯一索引，确保一对用户只能成为一次好友
         entity.HasIndex(e => new { e.User1Id, e.User2Id }).IsUnique();
     });
    }
}

//dotnet ef migrations add InitialCreate --context UserDbContext