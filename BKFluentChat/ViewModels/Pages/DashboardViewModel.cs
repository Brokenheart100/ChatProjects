using System.Diagnostics;

namespace BKFluentChat.ViewModels.Pages
{
    public partial class DashboardViewModel : ObservableObject
    {
        [ObservableProperty]
        private int _counter = 0;

        [RelayCommand]
        private void OnCounterIncrement()
        {
            Counter++;
            Debug.WriteLine($"couter {Counter}");
        }
    }
}
