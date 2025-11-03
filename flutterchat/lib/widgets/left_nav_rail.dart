import 'package:flutter/material.dart';

// 左侧导航栏组件，继承无状态组件StatelessWidget
class LeftNavRail extends StatelessWidget {
  // 当前选中的导航项索引（用于高亮显示选中状态）
  final int selectedIndex;
  // 导航项选中状态变化时的回调函数（参数为新选中的索引）
  final ValueChanged<int> onDestinationSelected;

  // 构造函数：接收选中索引和选中变化回调，均为必选参数
  const LeftNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  // 构建组件UI
  @override
  Widget build(BuildContext context) {
    // 导航栏容器：固定宽度60，背景色为深灰色（#363636）
    return Container(
      width: 60,
      color: const Color(0xFF363636),
      // 垂直布局容器：包含头像、导航图标等内容
      child: Column(
        children: [
          // 顶部间距（20像素）
          const SizedBox(height: 20),
          // 用户头像：圆形，半径20，使用本地资源图片
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/Image/30.jpg'),
          ),
          // 头像与下方导航图标之间的间距（20像素）
          const SizedBox(height: 20),
          // 构建导航图标：聊天图标（索引0）
          _buildNavIcon(Icons.chat_bubble, 0),
          // 构建导航图标：联系人图标（索引1）
          _buildNavIcon(Icons.people, 1),
          // 构建导航图标：星标图标（索引2，带有通知标记）
          _buildNavIcon(Icons.star, 2, hasNotification: true),
          // 构建导航图标：标签图标（索引3）
          _buildNavIcon(Icons.tag, 3),
          // 构建导航图标：网格视图图标（索引4）
          _buildNavIcon(Icons.grid_view_rounded, 4),
          // 填充剩余空间，将下方图标推至底部
          const Spacer(),
          // 构建导航图标：邮件图标（索引5）
          _buildNavIcon(Icons.mail, 5),
          // 构建导航图标：设备图标（索引6）
          _buildNavIcon(Icons.phone_android, 6),
          // 构建导航图标：菜单图标（索引7）
          _buildNavIcon(Icons.menu, 7),
          // 底部间距（20像素）
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 私有方法：构建单个导航图标项
  // 参数：icon（图标数据）、index（当前项索引）、hasNotification（是否显示通知标记，默认false）
  Widget _buildNavIcon(
    IconData icon,
    int index, {
    bool hasNotification = false,
  }) {
    // 判断当前项是否为选中状态（索引匹配）
    bool isSelected = selectedIndex == index;
    // 可点击容器：点击时触发选中回调
    return GestureDetector(
      onTap: () => onDestinationSelected(index), // 点击时将当前索引传入回调
      // 图标容器：固定宽高50，用于限制点击区域和图标位置
      child: SizedBox(
        height: 50,
        width: 50,
        // 层叠布局：用于在图标上方叠加通知标记
        child: Stack(
          alignment: Alignment.center, // 子组件居中对齐
          children: [
            // 导航图标：选中时为白色，未选中时为半透明白色，大小28
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 28,
            ),
            // 若有通知标记，显示红色小圆点（位置：右上角）
            if (hasNotification)
              Positioned(
                top: 10, // 距离顶部10像素
                right: 10, // 距离右侧10像素
                child: Container(
                  width: 8, // 宽8像素
                  height: 8, // 高8像素
                  decoration: const BoxDecoration(
                    color: Colors.red, // 红色背景
                    shape: BoxShape.circle, // 圆形
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
