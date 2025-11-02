using System.Collections.ObjectModel;
using Wpf.Ui.Controls;

namespace BKFluentChat.ViewModels.Windows
{
    public partial class MainWindowViewModel : ObservableObject
    {
        [ObservableProperty]
        private string _applicationTitle = "WPF UI - BKFluentChat";

        [ObservableProperty]
        private ObservableCollection<object> _menuItems = new()
        {
            new NavigationViewItem()
            {
                Content = "Home",
                Icon = new SymbolIcon { Symbol = SymbolRegular.Home24 },
                TargetPageType = typeof(Views.Pages.DashboardPage)
            },
            new NavigationViewItem()
            {
                Content = "Data",
                Icon = new SymbolIcon { Symbol = SymbolRegular.DataHistogram24 },
                TargetPageType = typeof(Views.Pages.DataPage)
            },
            new NavigationViewItem()
            {
            Content = "Chat",
            Icon = new SymbolIcon { Symbol = SymbolRegular.DataHistogram24 },
            TargetPageType = typeof(Views.Pages.ChatPage)
            },
            new NavigationViewItem()
            {
                Content = "联系人", // Contacts
                Icon = new SymbolIcon { Symbol = SymbolRegular.People24 },
                TargetPageType = typeof(Views.Pages.ContactsPage)
            },
            new NavigationViewItem()
            {
                Content = "test", // Contacts
                Icon = new SymbolIcon { Symbol = SymbolRegular.People24 },
                TargetPageType = typeof(Views.Pages.TestPage)
            },
        };

        [ObservableProperty]
        private ObservableCollection<object> _footerMenuItems = new()
        {
            new NavigationViewItem()
            {
                Content = "Settings",
                Icon = new SymbolIcon { Symbol = SymbolRegular.Settings24 },
                TargetPageType = typeof(Views.Pages.SettingsPage)
            }
        };

        [ObservableProperty]
        private ObservableCollection<MenuItem> _trayMenuItems = new()
        {
            new MenuItem { Header = "Home", Tag = "tray_home" }
        };
    }
}
