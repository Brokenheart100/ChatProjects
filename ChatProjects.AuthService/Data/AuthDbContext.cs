using ChatProjects.AuthService.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.AuthService.Data;

// 继承自 IdentityDbContext，并指定我们自定义的 AppUser 类
public class AuthDbContext : IdentityDbContext<AppUser>
{
    public AuthDbContext(DbContextOptions<AuthDbContext> options) : base(options)
    {
    }
}