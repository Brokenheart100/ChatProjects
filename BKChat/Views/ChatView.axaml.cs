using BKChat.ViewModels;
using ReactiveUI.Avalonia;

namespace BKChat;

public partial class ChatView : ReactiveUserControl<ChatViewModel>
{
    public ChatView()
    {
        InitializeComponent();
    }
}
