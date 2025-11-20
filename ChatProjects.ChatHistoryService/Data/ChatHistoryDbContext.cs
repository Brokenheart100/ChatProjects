using ChatProjects.ChatHistoryService.Models;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.ChatHistoryService.Data;

public class ChatHistoryDbContext : DbContext
{
    public ChatHistoryDbContext(DbContextOptions<ChatHistoryDbContext> options) : base(options)
    {
    }

    public DbSet<Message> Messages { get; set; }

    // public DbSet<Conversation> Conversations { get; set; }
    public DbSet<Participant> Participants { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.Id);

            // 【【【 关键索引配置 】】】
            entity.HasIndex(e => new { e.ConversationId, e.SentAt })
                .IsDescending(false, true); // ConversationId 升序, SentAt 降序
        });
    }
}