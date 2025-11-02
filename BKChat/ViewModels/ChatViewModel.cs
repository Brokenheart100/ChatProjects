using ReactiveUI;
using System.Collections.ObjectModel;
using System.Linq;
using BKChat.Models; // 确保你引用了Models命名空间
using ReactiveUI.SourceGenerators; // 引入 Fody Helper

namespace BKChat.ViewModels;

// ChatViewModel 现在是负责所有聊天逻辑的“页面”
public partial class ChatViewModel : ReactiveObject, IRoutableViewModel
{
    public string? UrlPathSegment => "Chat";
    public IScreen HostScreen { get; }

    [Reactive]
    public Conversation? SelectedConversation { get; set; }

    public ObservableCollection<Conversation> Conversations { get; }

    // --- 构造函数 ---
    public ChatViewModel(IScreen screen)
    {
        HostScreen = screen;

        // --- 填充示例数据 (这段逻辑从旧的 MainWindowViewModel 移动到这里) ---
        var convo1 = new Conversation { Name = "BKTV", LastMessage = "【来自未来的英...", Timestamp = "昨天 11:28" };
        convo1.Messages.Add(new Message { Content = "最后在干一个月回来, 实在顶不住了, 像行尸走肉", IsSentByMe = true });
        convo1.Messages.Add(new Message { Content = "行嘛", IsSentByMe = false });
        convo1.Messages.Add(new Message { Content = "或者换一个城市", IsSentByMe = false });

        var convo2 = new Conversation { Name = "卡2小号", LastMessage = "https://wx691d...", Timestamp = "11:30" };
        convo2.Messages.Add(new Message { Content = "你好，在吗？", IsSentByMe = false });
        convo2.Messages.Add(new Message { Content = "在的，请讲", IsSentByMe = true });
        convo2.Messages.Add(new Message { Content = "在的，请讲", IsSentByMe = true });
        convo2.Messages.Add(new Message { Content = "在的，请讲", IsSentByMe = true });
        convo2.Messages.Add(new Message { Content = "在的，请讲", IsSentByMe = true });
        convo2.Messages.Add(new Message { Content = "在的，请讲", IsSentByMe = true });


        Conversations = [convo1, convo2];

        // 默认选中第一个会话
        SelectedConversation = Conversations[1];
    }
}