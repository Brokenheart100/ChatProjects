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
        // --- 状态区 ---
        MenuItem(key: 'status_online', label: '🟢  我在线上'),
        MenuItem(key: 'status_qme', label: '🟡  Q我吧'),
        MenuItem(key: 'status_away', label: '🌙  离开'),
        MenuItem(key: 'status_busy', label: '⛔  忙碌'),
        MenuItem(key: 'status_dnd', label: '🚫  请勿打扰'),
        MenuItem(key: 'status_hidden', label: '🕵️  隐身'), // 或者 👻
        MenuItem(key: 'status_offline', label: '⚫  离线'),

        MenuItem.separator(), // --- 分割线 ---

        // --- 设置区 ---
        MenuItem(
          key: 'toggle_sound',
          label: '🔊  打开所有声音',
          checked: true, // 勾选状态
        ),
        MenuItem(key: 'toggle_blink', label: '😐  关闭头像闪动'),

        MenuItem.separator(), // --- 分割线 ---

        // --- 功能区 ---
        // 原生菜单无法右对齐快捷键，只能写在文字里
        MenuItem(key: 'action_lock', label: '🔒  锁定 (Ctrl+Alt+L)'),
        MenuItem(key: 'action_screenshot', label: '✂️  截图 (Ctrl+Alt+A)'),
        MenuItem(key: 'action_transfer', label: '⚡  QQ闪传'),

        MenuItem.separator(), // --- 分割线 ---

        // --- 核心操作 ---
        MenuItem(key: 'show_window', label: '🪟  打开主面板'),
        MenuItem(key: 'exit_app', label: '🚪  退出'),
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

  @override
  void onTrayIconRightMouseDown() {
    // 这一步是关键，必须手动调用 popUpContextMenu
    trayManager.popUpContextMenu();
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
        logger.i("🚪 用户通过托盘菜单退出应用");
        trayManager.destroy();
        exit(0);
    }
  }

  /// 移除托盘 (清理)
  void destroy() {
    trayManager.destroy();
  }
}
