using BKFluentChat.ViewModels.Pages;
using Wpf.Ui.Abstractions.Controls;
using Wpf.Ui.Controls;

namespace BKFluentChat.Views.Pages
{
    /// <summary>
    /// ContactsPage.xaml 的交互逻辑
    /// </summary>
    public partial class ContactsPage : INavigableView<ContactsViewModel>
    {
        public ContactsViewModel ViewModel { get; }

        public ContactsPage(ContactsViewModel viewModel)
        {
            ViewModel = viewModel;
            DataContext = this; // 保持与 ChatPage 一致的上下文设置
            InitializeComponent();
        }
    }
}
