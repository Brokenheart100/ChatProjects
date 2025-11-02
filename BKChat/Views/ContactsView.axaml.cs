using BKChat.ViewModels;
using ReactiveUI.Avalonia;
    
namespace BKChat;

public partial class ContactsView : ReactiveUserControl<ContactsViewModel>
{
    public ContactsView()
    {
        InitializeComponent();
    }
}