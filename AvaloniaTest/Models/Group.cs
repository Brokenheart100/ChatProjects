using System.Collections.ObjectModel;
using System.Linq;

namespace AvaloniaTest.Models;

public class Group
{
    public string Name { get; set; } = "Default Group";
    public ObservableCollection<Contact> Contacts { get; } = new();

    // QQ显示的是 "在线人数/总人数"，这里我们简化一下
    public int OnlineCount => Contacts.Count(c => c.IsOnline);
    public int TotalCount => Contacts.Count;
    public string DisplayCountText => $"{OnlineCount}/{TotalCount}";
}