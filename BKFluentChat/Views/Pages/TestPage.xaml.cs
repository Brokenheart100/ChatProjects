using BKFluentChat.ViewModels.Pages;
using Wpf.Ui.Abstractions.Controls;

namespace BKFluentChat.Views.Pages
{
    /// <summary>
    /// TestPage.xaml 的交互逻辑
    /// </summary>
    public partial class TestPage : INavigableView<TestViewModel>
    {
        public TestViewModel ViewModel { get; }
        public TestPage(TestViewModel viewModel)
        {
            ViewModel = viewModel;
            DataContext = this;
            InitializeComponent();
        }
        private void AddButton_Click(object sender, RoutedEventArgs e)
        {
            // 当按钮被点击时，手动打开附加在它上面的 ContextMenu
            //AddButton.ContextMenu.IsOpen = true;
        }
    }
}
