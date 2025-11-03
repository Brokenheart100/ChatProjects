// AuthService/Extensions/IdentityServiceExtensions.cs
using ChatProjects.AuthService.Data;
using ChatProjects.AuthService.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;

namespace ChatProjects.AuthService.Extensions;

public static class IdentityServiceExtensions
{
    public static IServiceCollection AddIdentityServices(this IServiceCollection services)
    {
        services.AddIdentity<AppUser, IdentityRole>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequiredLength = 6;
            })
            .AddEntityFrameworkStores<AuthDbContext>()
            .AddDefaultTokenProviders();

        return services;
    }
}