using Avalonia.Media;
using BKChat.Models;
using ReactiveUI;
using System.Collections.ObjectModel;
using ReactiveUI.SourceGenerators;

public partial class ContactsViewModel : ReactiveObject, IRoutableViewModel
{
    public string? UrlPathSegment => "Contacts";
    public IScreen HostScreen { get; }

    // TreeView 的数据源
    public ObservableCollection<ContactGroup> ContactGroups { get; }

    // TreeView 的当前选中项 (可以是Group或Contact)
    [Reactive]
    public object? SelectedItem { get; set; }

    // 专门用于右侧详情页的数据上下文
    [Reactive]
    public Contact? SelectedContact { get; private set; }

    public ContactsViewModel(IScreen screen)
    {
        HostScreen = screen;
        ContactGroups = new ObservableCollection<ContactGroup>();

        // 核心响应式逻辑：连接左侧的选择和右侧的显示
        //this.WhenAnyValue(x => x.SelectedItem)
        //    .Subscribe(selected =>
        //    {
        //        // 如果选中的项是一个 Contact，我们就更新 SelectedContact
        //        SelectedContact = selected as Contact;
        //    });

        // --- 填充示例数据 ---
        var group1 = new ContactGroup { Name = "《高中美男团》", IsExpanded = true }; // 默认展开
        var kitayaContact = new Contact { Remark = "东海帝皇official", Name = "Kitaya", AvatarUrl = "/Assets/avatar-kitaya.png", StatusText = "[听歌中] 花园在...", StatusColor = Brushes.Orange, StatusIcon = "\uf001" };
        group1.Contacts.Add(kitayaContact);
        group1.Contacts.Add(new Contact { Remark = "英俊潇洒-坤", Name = "坤", AvatarUrl = "/Assets/avalonia-logo.ico", StatusText = "[在线]", StatusColor = Brushes.Green, StatusIcon = "\uf111" });

        var group2 = new ContactGroup { Name = "ε-世界线" };
        group2.Contacts.Add(new Contact { Remark = "冈部伦太郎", Name = "冈部伦太郎", AvatarUrl = "/Assets/avalonia-logo.ico", StatusText = "[在线]", StatusColor = Brushes.Green, StatusIcon = "\uf111" });

        ContactGroups.Add(new ContactGroup { Name = "我的设备" });
        ContactGroups.Add(new ContactGroup { Name = "特别关心" });
        ContactGroups.Add(group2);
        ContactGroups.Add(group1);

        // 设置默认选中项，以便启动时右侧有内容
        SelectedItem = kitayaContact;
    }
}