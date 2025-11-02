using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;

namespace BKFluentChat.Models
{
    public partial class ContactGroup : ObservableObject
    {
        // 分组名称
        [ObservableProperty]
        private string _name;

        // 分组计数器，例如 "22/29"
        [ObservableProperty]
        private string _counter;

        // 该分组下的联系人列表 (为未来的扩展做准备)
        [ObservableProperty]
        private ObservableCollection<Contact> _contacts = [];

        // 控制分组是否展开
        [ObservableProperty]
        private bool _isExpanded = true;
    }
}