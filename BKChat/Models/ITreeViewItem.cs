using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKChat.Models
{
    // 定义一个“树节点”应该具备的基本要素
    public interface ITreeViewItem
    {
        // 所有节点都应该有一个可供显示的标题
        string DisplayTitle { get; }

        // 所有节点都“可能”有子节点
        ObservableCollection<ITreeViewItem> Children { get; }
    }
}
