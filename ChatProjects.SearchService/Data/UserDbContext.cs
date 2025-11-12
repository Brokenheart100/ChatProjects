// 文件: ChatProjects.SearchService/Data/UserDbContext.cs
using ChatProjects.SearchService.Models;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.SearchService.Data;

public class UserDbContext : DbContext
{
    public UserDbContext(DbContextOptions<UserDbContext> options) : base(options) { }
    public DbSet<AppUser> Users { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<AppUser>().ToTable("AspNetUsers");
    }
}