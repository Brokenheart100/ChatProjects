using Avalonia;
using Avalonia.Layout;

namespace BKChat.Models;

// Message 也是一个简单的 POCO
public class Message
{
    public string? Content { get; set; }
    public bool IsSentByMe { get; set; }

    // 这些UI相关的计算属性也可以保留在这里，因为它们是无状态的
    public HorizontalAlignment Alignment => IsSentByMe ? HorizontalAlignment.Right : HorizontalAlignment.Left;
    public Thickness Margin => IsSentByMe ? new Thickness(50, 5, 5, 5) : new Thickness(5, 5, 50, 5);
}