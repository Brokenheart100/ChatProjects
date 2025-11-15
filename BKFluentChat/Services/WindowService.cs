// 文件: BKFluentChat/Services/WindowService.cs
using BKFluentChat.Views.Windows;
using Microsoft.Extensions.DependencyInjection; // 需要引入
using System;

namespace BKFluentChat.Services;

public class WindowService : IWindowService
{
    private readonly IServiceProvider _serviceProvider;

    public WindowService(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public void ShowSearchWindow()
    {
        // 从依赖注入容器获取一个新的 SearchWindow 实例
        var searchWindow = _serviceProvider.GetService<SearchWindow>();
        searchWindow?.Show();
    }
}