// File: BKFluentChat\ViewModels\Pages\ContactsViewModel.cs (Simplified Version without Tabs)
using BKFluentChat.Models;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Collections.ObjectModel;
using System.Diagnostics;

namespace BKFluentChat.ViewModels.Pages
{
    public partial class ContactsViewModel : ObservableObject
    {
        // 唯一的列表属性：用于驱动联系人分组列表
        [ObservableProperty]
        private ObservableCollection<ContactGroup> _contactGroups;

        // 用于存储当前被选中的联系人
        //[ObservableProperty]
        private Contact _selectedContact;
        // 2. 实现带有调试信息的完整公开属性
        public Contact SelectedContact
        {
            get => _selectedContact;
            set
            {
                if (SetProperty(ref _selectedContact, value))
                {
                    // 当属性值成功改变后，执行这里的代码

                    // 输出一条调试信息到 Visual Studio 的“输出”窗口。
                    // `value?` 是 null 条件运算符，如果 value 不为 null，则访问 Name，否则整体返回 null。
                    // `?? "null"` 是 null 合并运算符，如果前面的表达式结果是 null，则使用 "null" 字符串。
                    Debug.WriteLine($"[DEBUG] SelectedContact has been set to: {value?.Name ?? "null"}");

                    // 如果您有任何依赖于 SelectedContact 状态的命令，可以在这里通知它们更新。
                    // 例如: SomeCommand.NotifyCanExecuteChanged();
                }
            }
        }
        public ContactsViewModel()
        {
            LoadContactGroups();
        }

        // 响应用户点击的命令
        [RelayCommand]
        private void SelectContact(Contact contact)
        {
            SelectedContact = contact;
        }

        // 一个统一的方法，用于加载所有联系人分组和联系人数据
        private void LoadContactGroups()
        {
            // 1. 初始化联系人分组集合
            ContactGroups = new ObservableCollection<ContactGroup>
            {
                new ContactGroup { Name = "我的设备", Counter = "1" },
                new ContactGroup { Name = "特别关心", Counter = "0/0" },
                new ContactGroup { Name = "【ε-世界线】", Counter = "22/29" },
                new ContactGroup { Name = "【β-世界线】", Counter = "24/43" },
                new ContactGroup { Name = "【γ-世界线】", Counter = "3/4" },
                new ContactGroup { Name = "【λ-世界线】", Counter = "1/4" },
                new ContactGroup { Name = "[Asshole的大...", Counter = "18/33" }
            };

            // 2. 创建“高中美男团”分组并填充其内容
            var hsmntGroup = new ContactGroup { Name = "《高中美男团》", Counter = "2/6" };

            // 为“东海帝皇”创建完整的详细数据
            var teio = new Contact
            {
                Name = "Kitaya",
                Status = "[😋听歌中] 花园在...",
                AvatarUrl = "pack://application:,,,/Assets/contact_avatar1.png",
                QqNumber = "QQ 3303545220",
                LikesCount = 1010,
                Gender = "男",
                Age = 25,
                BirthDate = "6月20日",
                ZodiacSign = "双子座",
                Remark = "东海帝皇official",
                GroupName = "《高中...",
                Signature = "花园在召唤你",
            };
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo1.png");
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo2.png");
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo3.png");
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo4.png");
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo5.png");
            teio.FeaturedPhotos.Add("pack://application:,,,/Assets/photo6.png");

            var kun = new Contact
            {
                Name = "【英俊潇洒-坤...",
                Status = "[⚫在线]",
                AvatarUrl = "pack://application:,,,/Assets/contact_avatar2.png",
                QqNumber = "QQ 123456789",
                Remark = "坤哥",
                Signature = "只因你太美"
            };

            // 将两个联系人添加到分组中
            hsmntGroup.Contacts.Add(teio);
            hsmntGroup.Contacts.Add(kun);

            // 3. 将创建好的分组添加到主列表中
            ContactGroups.Add(hsmntGroup);
        }
    }
}