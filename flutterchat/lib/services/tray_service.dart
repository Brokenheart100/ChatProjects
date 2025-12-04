import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/services/logger_service.dart';

class TrayService with TrayListener {
  // 单例模式
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  /// 初始化托盘
  Future<void> init() async {
    // 1. 添加监听器
    trayManager.addListener(this);

    // 2. 设置图标
    // Windows 下必须使用 .ico 文件
    // 注意：assets 路径在打包后可能需要调整，但在 Debug 模式下通常如下：
    String iconPath = Platform.isWindows
        ? 'assets/image/app_icon.ico' // 确保你放了这个文件
        : 'assets/image/2.jpg';

    await trayManager.setIcon(iconPath);

    // 3. 设置提示文字 (鼠标悬停时显示)
    await trayManager.setToolTip('FlutterChat');

    // 4. 创建右键菜单
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '显示/隐藏',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: '退出',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  /// 处理托盘图标点击事件 (左键)
  @override
  void onTrayIconMouseDown() async {
    // 逻辑：如果窗口可见，则隐藏；如果隐藏/最小化，则显示并置顶
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      windowManager.hide();
    } else {
      windowManager.show();
      windowManager.focus();
    }
  }

  /// 处理右键菜单点击事件
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          windowManager.hide();
        } else {
          windowManager.show();
          windowManager.focus();
        }
        break;
      case 'exit_app':
        // 彻底退出应用
        logger.i("🚪 用户通过托盘菜单退出应用");
        // 移除托盘图标
        trayManager.destroy();
        // 退出进程
        exit(0);
        break;
    }
  }

  /// 移除托盘 (清理)
  void destroy() {
    trayManager.destroy();
  }
}
