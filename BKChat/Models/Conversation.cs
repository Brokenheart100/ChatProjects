using System.Collections.ObjectModel;

namespace BKChat.Models;

// 这是一个简单的 POCO (Plain Old C# Object)
// 它不继承任何基类，也不需要任何特性
public class Conversation
{
    public string? AvatarUrl { get; set; }
    public string? Name { get; set; }
    public string? LastMessage { get; set; }
    public string? Timestamp { get; set; }

    // 集合本身需要是 ObservableCollection 以便UI可以观察到添加/删除操作
    public ObservableCollection<Message> Messages { get; } = [];

    // 计算属性依然有效
    public string ChatTitle => $"{Name} ({Messages.Count})";
}