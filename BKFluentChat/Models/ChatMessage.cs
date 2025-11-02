using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKFluentChat.Models
{
    public partial class ChatMessage : ObservableObject
    {
        // 消息发送者的名字
        [ObservableProperty]
        private string _author;

        // 消息内容
        [ObservableProperty]
        private string _text;

        // 消息发送时间
        [ObservableProperty]
        private DateTime _timestamp;

        // 头像的URL或者本地路径
        [ObservableProperty]
        private string _avatarUrl;

        // 关键属性：标记这条消息是否是当前用户自己发送的
        [ObservableProperty]
        private bool _isSentByMe;
    }
}
