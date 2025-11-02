using System.Linq;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Avalonia.Themes.Fluent;
using BKChat.ViewModels;
using BKChat.Views;
using ReactiveUI;
using Splat;

namespace BKChat;

public partial class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
#if DEBUG
        this.AttachDeveloperTools();
#endif
    }

    public override void OnFrameworkInitializationCompleted()
    {

        Locator.CurrentMutable.Register(() => new ChatView(), typeof(IViewFor<ChatViewModel>));
        Locator.CurrentMutable.Register(() => new ContactsView(), typeof(IViewFor<ContactsViewModel>));

        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            desktop.MainWindow = new MainWindow
            {
                DataContext = new MainWindowViewModel(),
            };
        }

        base.OnFrameworkInitializationCompleted();
    }
}