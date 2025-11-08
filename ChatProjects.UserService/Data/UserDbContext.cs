using ChatProjects.UserService.Entities;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.UserService.Data;

public class UserDbContext : DbContext
{
    public UserDbContext(DbContextOptions<UserDbContext> options) : base(options)
    {
    }

    public DbSet<AppUser> Users { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 确保 EF Core 知道 AppUser 实体对应的是 AspNetUsers 表
        modelBuilder.Entity<AppUser>().ToTable("AspNetUsers");
    }
}

//dotnet ef migrations add InitialCreate --context UserDbContext