using BKChat.Models; // 确保引用了Models，如果Contact在同一个文件则不需要
using System.Collections.ObjectModel;
using System.Linq;

namespace BKChat.Models;

public class ContactGroup
{
    public string Name { get; set; } = "默认分组";

    // --- 确保这个属性存在且是 public 的 ---
    // 这个属性是 HierarchicalDataTemplate 的 ItemsSource 绑定的目标
    public ObservableCollection<Contact> Contacts { get; } = new();

    // --- 确保这些用于UI绑定的计算属性也存在 ---
    public int OnlineCount => Contacts.Count(c => c.IsOnline);
    public int TotalCount => Contacts.Count;
    public string DisplayCount => $"{OnlineCount}/{TotalCount}";

    // --- 确保这个用于 TreeViewItem 状态绑定的属性也存在 ---
    public bool IsExpanded { get; set; } = false;
}