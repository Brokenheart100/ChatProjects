// File: BKFluentChat\ViewModels\Pages\ChatViewModel.cs
using BKFluentChat.Models;
using System.Collections.ObjectModel;
using System.Diagnostics;

namespace BKFluentChat.ViewModels.Pages
{
    public partial class ChatViewModel : ObservableObject
    {
        // (左侧) 存储所有会话的集合
        [ObservableProperty]
        private ObservableCollection<Conversation> _conversations;

        // 关键属性：存储当前被选中的会话
        //[ObservableProperty]
        private Conversation _selectedConversation;


        // 2. 实现完整的公开属性
        public Conversation SelectedConversation
        {
            get => _selectedConversation;
            set
            {
                // 使用 CommunityToolkit.Mvvm 提供的 SetProperty 方法
                // 这个方法会检查新值和旧值是否相同，如果不同，
                // 它会更新字段并自动触发 PropertyChanged 事件。
                // 这是MVVM中属性变更通知的标准做法。
                if (SetProperty(ref _selectedConversation, value))
                {
                    // 当属性成功改变后，我们在这里可以添加调试代码
                    // 这行代码将会在 Visual Studio 的“输出”窗口打印信息
                    Debug.WriteLine($"[DEBUG] SelectedConversation changed to: {value?.Name ?? "null"}");

                    // 如果有依赖于这个属性的命令，可以在这里通知它们更新状态
                    // 例如: SendMessageCommand.NotifyCanExecuteChanged();
                    OnPropertyChanged(nameof(CurrentMessages));
                }
            }
        }
        public ObservableCollection<ChatMessage> CurrentMessages => SelectedConversation?.Messages;
        // 绑定到输入框的文本
        [ObservableProperty]
        private string _newMessageText;

        public ChatViewModel()
        {
            Conversations = [];
            LoadMockConversationsAndMessages();

            // 默认选中第一个会话
            SelectedConversation = Conversations.FirstOrDefault();
        }

        // 发送消息的命令
        [RelayCommand]
        private void SendMessage()
        {
            // 确保有选中的会话并且输入不为空
            if (SelectedConversation == null || string.IsNullOrWhiteSpace(NewMessageText))
                return;

            var newMessage = new ChatMessage
            {
                Author = "我",
                Text = NewMessageText,
                Timestamp = DateTime.Now,
                AvatarUrl = "pack://application:,,,/Assets/avatar_me.png",
                IsSentByMe = true
            };

            // 将新消息添加到当前选中会话的消息列表里
            SelectedConversation.Messages.Add(newMessage);

            // 更新会话的最新消息预览
            SelectedConversation.LatestMessage = NewMessageText;
            SelectedConversation.Timestamp = DateTime.Now.ToString("HH:mm");

            NewMessageText = string.Empty; // 清空输入框
        }

        // 修改模拟数据加载，为每个会话创建独立的消息
        private void LoadMockConversationsAndMessages()
        {
            var conv1 = new Conversation
            {
                Name = "高九复读...",
                AvatarUrl = "/Assets/wpfui-icon-256.png",
                LatestMessage = "[小号1]: 深圳没...",
                Timestamp = "20:27",
                IsMuted = true
            };
            conv1.Messages.Add(new ChatMessage { Author = "小号1", Text = "深圳没房，感觉人生无望...", IsSentByMe = false, AvatarUrl = "pack://application:,,,/Assets/conv1.png" });

            var conv2 = new Conversation
            {
                Name = "USUSUSUS",
                AvatarUrl = "/Assets/wpfui-icon-256.png",
                LatestMessage = "感觉不如花果园",
                Timestamp = "19:57",
                IsMuted = true
            };
            conv2.Messages.Add(new ChatMessage { Author = "学历姐", Text = "有点心动，出门就是cbd", IsSentByMe = false, AvatarUrl = "pack://application:,,,/Assets/avatar1.png" });
            conv2.Messages.Add(new ChatMessage { Author = "清真bot", Text = "感觉不如花果园", IsSentByMe = false, AvatarUrl = "pack://application:,,,/Assets/avatar2.png" });
            conv2.Messages.Add(new ChatMessage { Author = "我", Text = "确实，花果园才是宇宙中心！", IsSentByMe = true, AvatarUrl = "pack://application:,,,/Assets/avatar_me.png" });

            var conv3 = new Conversation
            {
                Name = "BKTV",
                AvatarUrl = "/Assets/wpfui-icon-256.png",
                LatestMessage = "【来自未来的英...",
                Timestamp = "昨天 18:36",
                IsMuted = false
            };
            conv3.Messages.Add(new ChatMessage { Author = "BKTV", Text = "【来自未来的英雄联盟】", IsSentByMe = false, AvatarUrl = "pack://application:,,,/Assets/conv4.png" });
            conv3.Messages.Add(new ChatMessage { Author = "我", Text = "这也太帅了吧！", IsSentByMe = true, AvatarUrl = "pack://application:,,,/Assets/avatar_me.png" });

            Conversations.Add(conv1);
            Conversations.Add(conv2);
            Conversations.Add(conv3);
        }
    }
}