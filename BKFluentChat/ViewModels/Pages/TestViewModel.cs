using BKFluentChat.Models;
using BKFluentChat.Services;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKFluentChat.ViewModels.Pages
{
    public partial class TestViewModel : ObservableObject
    {
        // --- 2. 核心新增：添加一个私有字段来存储 logger 实例 ---
        private readonly ILogger<TestViewModel> _logger;
        // ----------------------------------------------------
        private readonly IWindowService _windowService;
        [ObservableProperty]
        private ObservableCollection<ContactGroup> _contactGroups;

        [ObservableProperty]
        private Contact _selectedContact;

        // 3. 核心修改：更新构造函数以接收 ILogger
        public TestViewModel(ILogger<TestViewModel> logger,IWindowService windowService)
        {
            _logger = logger;
            _windowService = windowService;
            LoadMockData();

        }

        [RelayCommand]
        private void CreateGroup()
        {
            // TODO: 在这里实现创建群聊的逻辑，例如弹出一个新的对话框
            Debug.WriteLine("创建群聊命令被执行！");
        }

        [RelayCommand]
        private void AddFriend()
        {
            _windowService.ShowSearchWindow();
            _logger.LogInformation("AddFriend command executed.");
        }

        [RelayCommand]
        private void SendFile()
        {
            // TODO: 在这里实现闪传文件的逻辑
            Debug.WriteLine("闪传文件命令被执行！");
        }
        [RelayCommand]
        private void SelectItem(object item)
        {
            // 当点击一个 Contact 时，更新 SelectedContact
            if (item is Contact contact)
            {
                SelectedContact = contact;
                Debug.WriteLine($"[DEBUG] SelectedContact changed to: {contact.Name}");
            }
            // (如果点击分组，我们暂时不改变选中项)
        }
        private void LoadMockData()
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
            teio.FeaturedPhotos.Add("/Assets/wpfui-icon-1024.png");
            teio.FeaturedPhotos.Add("/Assets/wpfui-icon-1024.png");
            teio.FeaturedPhotos.Add("/Assets/wpfui-icon-1024.png");
            teio.FeaturedPhotos.Add("/Assets/wpfui-icon-1024.png");
            teio.FeaturedPhotos.Add("/Assets/wpfui-icon-1024.png");

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
