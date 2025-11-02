using Avalonia.Media;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKChat.Models
{
    public class Contact : ITreeViewItem
    {
        // --- ITreeViewItem 接口实现 ---
        public string DisplayTitle => Remark;

        // 联系人是“叶子节点”，所以它的子节点集合永远是空的
        public ObservableCollection<ITreeViewItem> Children { get; } = new();
        public string? AvatarUrl { get; set; }
        public string Name { get; set; } = "Default Name";
        public string QqNumber { get; set; } = "000000";
        public string Status { get; set; } = "在线";
        public int Likes { get; set; }

        public string Gender { get; set; } = "男";
        public int Age { get; set; } = 25;
        public string Birthday { get; set; } = "6月20日";
        public string ZodiacSign { get; set; } = "双子座";
        public int Level { get; set; } = 4; // 太阳月亮星星等级

        public string Remark { get; set; } = string.Empty;
        public string Group { get; set; } = "我的好友";
        public string Signature { get; set; } = "这个人很懒，什么都没留下。";
        public string StatusText { get; set; } = "离线";
        public string StatusIcon { get; set; } = "\uf10c"; // FontAwesome: circle
        public IBrush StatusColor { get; set; } = Brushes.Gray;
        // 照片列表
        public ObservableCollection<string> Photos { get; } = [];
        public bool IsOnline { get; internal set; }
    }
}
