// File: BKFluentChat\Models\Conversation.cs
using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel; // 引入这个命名空间

namespace BKFluentChat.Models
{
    public partial class Conversation : ObservableObject
    {
        [ObservableProperty]
        private string _name;

        [ObservableProperty]
        private string _avatarUrl;

        [ObservableProperty]
        private string _latestMessage;

        [ObservableProperty]
        private string _timestamp;

        [ObservableProperty]
        private bool _isMuted;

        // 新增属性：存储此会话的所有消息
        [ObservableProperty]
        private ObservableCollection<ChatMessage> _messages = new ObservableCollection<ChatMessage>();
    }
}