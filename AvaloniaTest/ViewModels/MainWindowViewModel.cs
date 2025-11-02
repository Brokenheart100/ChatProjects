using Avalonia.Media.Imaging;
using AvaloniaTest.Models;
using System;
using System.Collections.ObjectModel;

namespace AvaloniaTest.ViewModels;

public class MainWindowViewModel : ViewModelBase
{
    public ObservableCollection<Group> Groups { get; }

    public MainWindowViewModel()
    {
        Groups = new ObservableCollection<Group>();
        LoadData();
    }

    private void LoadData()
    {
        // 辅助函数，用于安全加载图片
        Bitmap? LoadBitmap(string path)
        {
            try
            {
                return new Bitmap(path);
            }
            catch (Exception) // 捕获文件未找到等异常
            {
                return null; // 返回null，让Image控件优雅地失败
            }
        }

        var group1 = new Group { Name = "《高中美男团》" };
        group1.Contacts.Add(new Contact
        {
            Avatar = LoadBitmap("Assets/avatar-kitaya.png"), // 使用辅助函数
            Name = "东海帝皇official...",
            Status = "[听歌中] 花园在..."
        });
        group1.Contacts.Add(new Contact
        {
            Avatar = LoadBitmap("Assets/avalonia-logo.ico"),
            Name = "【英俊潇洒-坤...",
            Status = "[在线]"
        });

        Groups.Add(new Group { Name = "我的设备" });
        Groups.Add(new Group { Name = "特别关心" });
        Groups.Add(new Group { Name = "【ε-世界线】" });
        Groups.Add(new Group { Name = "【β-世界线】" });
        Groups.Add(group1);
    }
}