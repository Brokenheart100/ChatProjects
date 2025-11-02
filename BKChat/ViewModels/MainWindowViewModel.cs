using ReactiveUI;
using System.Reactive;

namespace BKChat.ViewModels
{
    // 1. 继承 ViewModelBase, 实现 IScreen 接口
    public partial class MainWindowViewModel : ViewModelBase, IScreen
    {
        // 2. IScreen 接口要求一个 RoutingState 属性
        // 2. RoutingState 就是导航器。它维护着一个导航栈。
        // 它的泛型参数是 IRoutableViewMdel，表示所有可被导航的ViewModel都必须实现这个接口。
        public RoutingState Router { get; }
        public ReactiveCommand<Unit, IRoutableViewModel> GoChat { get; }
        public ReactiveCommand<Unit, IRoutableViewModel> GoContacts { get; }
        public MainWindowViewModel()
        {
            // 3. 初始化导航器
            Router = new RoutingState();

            // 4. 创建导航命令
            // Navigate.Execute 会将新的ViewModel压入导航栈
            GoChat = ReactiveCommand.CreateFromObservable(
                () => Router.Navigate.Execute(new ChatViewModel(this))
            );

            GoContacts = ReactiveCommand.CreateFromObservable(
                () => Router.Navigate.Execute(new ContactsViewModel(this))
            );
            // 5. 设置初始页面
            Router.Navigate.Execute(new ChatViewModel(this));
        }
    }
}
