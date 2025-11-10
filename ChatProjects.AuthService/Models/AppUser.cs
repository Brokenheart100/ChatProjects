using Microsoft.AspNetCore.Identity;

namespace ChatProjects.AuthService.Models
{
    public class AppUser : IdentityUser
    {
        public string? DisplayName { get; set; }
        public string? AvatarUrl { get; set; }
    }
}
