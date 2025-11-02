using Avalonia.Media;

namespace AvaloniaTest.Models;

public class Contact
{
    public IImage? Avatar { get; set; }
    public string Name { get; set; } = "Default Contact";
    public string Status { get; set; } = "[离线]";
    public bool IsOnline => !Status.Contains("离线"); // 简单逻辑判断是否在线
}