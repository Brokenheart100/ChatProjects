import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/repositories/auth_repository.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/app.dart';
import 'package:flutterchat/services/objectbox_service.dart';
import 'package:flutterchat/services/notification_service.dart';
import 'package:flutterchat/services/tray_service.dart';
import 'package:flutterchat/providers/services_provider.dart';

void main() async {
  // 1. 基础绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 2. 初始化 ObjectBox 数据库
  final objectBox = await ObjectBoxService.init();

  // 3. 初始化通知服务 (flutter_local_notifications)
  await NotificationService.init();

  // 4. 初始化系统托盘 (tray_manager)
  await TrayService().init();

  // 5. 配置桌面窗口
  const WindowOptions windowOptions = WindowOptions(
    size: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  // 6. Riverpod 容器初始化与依赖注入
  final container = ProviderContainer(
    overrides: [
      // 注入已初始化的数据库实例，覆盖默认的抛异常 Provider
      objectBoxProvider.overrideWithValue(objectBox),
    ],
  );

  // 7. 执行自动登录逻辑 (后台静默执行，不阻塞 UI 渲染)
  // 注意：这里不需要 await，让它在后台跑，App 先显示登录页或 Loading
  _performAutoLogin(container);

  // 8. 启动应用 UI
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(), // 来自 lib/app.dart
    ),
  );
}

Future<void> _performAutoLogin(ProviderContainer container) async {
  // 只需要这一行！
  // Repo 会负责：查 Account -> 恢复 Token -> 调 API -> 更新 Provider
  await container.read(authRepositoryProvider).attemptAutoLogin();
}
