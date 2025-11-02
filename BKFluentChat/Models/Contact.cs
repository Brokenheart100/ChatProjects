// File: BKFluentChat\Models\Contact.cs
using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;

namespace BKFluentChat.Models
{
    public partial class Contact : ObservableObject
    {
        // --- 基本信息 ---
        [ObservableProperty] private string _avatarUrl;
        [ObservableProperty] private string _name;
        [ObservableProperty] private string _status;
        [ObservableProperty] private string _qqNumber;
        [ObservableProperty] private int _likesCount;

        // --- 详细信息 ---
        [ObservableProperty] private string _gender;
        [ObservableProperty] private int _age;
        [ObservableProperty] private string _birthDate;
        [ObservableProperty] private string _zodiacSign; // 星座

        // --- 备注与签名 ---
        [ObservableProperty] private string _remark;
        [ObservableProperty] private string _groupName;
        [ObservableProperty] private string _signature;

        // --- 精选照片 ---
        [ObservableProperty]
        private ObservableCollection<string> _featuredPhotos = new();
    }
}