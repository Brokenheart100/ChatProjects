// 文件: BKFluentChat/ViewModels/Windows/SearchViewModel.cs
using BKFluentChat.Models; // 假设您有一个 SearchResult 模型
using System.Collections.ObjectModel;
using System.DirectoryServices;

namespace BKFluentChat.ViewModels.Windows;

// 临时的搜索结果模型，您可以根据后端 API 调整
public class SearchResult
{
    public string AvatarUrl { get; set; }
    public string Name { get; set; }
    public int MemberCount { get; set; }
    public string Status { get; set; }
    public ObservableCollection<string> Tags { get; set; }
    public string Description { get; set; }
}

public partial class SearchViewModel : ObservableObject
{
    [ObservableProperty]
    private string _searchTerm;

    [ObservableProperty]
    private ObservableCollection<SearchResult> _searchResults;

    public SearchViewModel()
    {
        // 加载一些模拟数据以便立刻看到效果
        LoadMockResults();
    }

    [RelayCommand]
    private void Search()
    {
        // TODO: 在这里调用 API 服务，根据 SearchTerm 获取真实数据
        // 目前，我们只打印日志
        System.Diagnostics.Debug.WriteLine($"正在搜索: {SearchTerm}");
    }

    private void LoadMockResults()
    {
        SearchResults = new ObservableCollection<SearchResult>
        {
            new() {
                Name = "ustc&iat高新校区租房群", AvatarUrl = "pack://application:,,,/Assets/group1.png", MemberCount = 1973, Status = "5+人在聊天",
                Tags = new ObservableCollection<string> { "男生多", "同学" }, Description = ""
            },
            new() {
                Name = "血源诅咒桌游", AvatarUrl = "pack://application:,,,/Assets/group2.png", MemberCount = 1812, Status = "10+人在聊天",
                Tags = new ObservableCollection<string> { "男生多", "游戏", "血源诅咒" }, Description = "血源诅咒版图桌游群，欢迎新老猎人"
            },
            new() {
                Name = "纽扣助手游戏交流群3", AvatarUrl = "pack://application:,,,/Assets/group3.png", MemberCount = 266, Status = "",
                Tags = new ObservableCollection<string> { "男生多" }, Description = ""
            },
        };
    }
}