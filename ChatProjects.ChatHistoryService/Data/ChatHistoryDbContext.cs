using ChatProjects.ChatHistoryService.Models;
using Microsoft.EntityFrameworkCore;

namespace ChatProjects.ChatHistoryService.Data;

public class ChatHistoryDbContext : DbContext
{
    public ChatHistoryDbContext(DbContextOptions<ChatHistoryDbContext> options) : base(options)
    {
    }

    public DbSet<Message> Messages { get; set; }

     public DbSet<Conversation> Conversations { get; set; }
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
        // 参与者表：复合主键
        modelBuilder.Entity<Participant>(entity =>
        {
            entity.HasKey(e => new { e.ConversationId, e.UserId });

            // 索引：查找“我参与的所有会话”
            entity.HasIndex(e => e.UserId);
        });

        // 会话表
        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(e => e.Id);
            // 索引：更新排序
            entity.HasIndex(e => e.LastMessageAt);
        });
    }
}