import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/router.dart'; // ✅ 核心：必须引入 router.dart
import 'package:flutterchat/services/logger_service.dart';
import 'package:flutterchat/services/objectbox_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    windowButtonVisibility: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 1. ✅ 初始化 ObjectBox (必须 await)
  final objectBox = await ObjectBoxService.init();

  // 2. ✅ 创建容器并【立即覆盖】Provider
  // 如果你之前的代码是先创建 container 再去 override，那是不对的 (Riverpod 2.0 推荐做法)
  // 或者如果你用了 container.updateOverrides(...) 也可以
  final container = ProviderContainer(
    overrides: [
      // 这一行是关键！把初始化的实例注入进去
      objectBoxProvider.overrideWithValue(objectBox),
    ],
  );

  try {
    final accountService = container.read(accountServiceProvider);
    final account = await accountService.getAccountForAutoLogin();

    if (account != null) {
      logger.i("main: 找到自动登录账户: ${account.username}");

      final api = container.read(apiServiceProvider);
      // 1. 恢复 Token
      await api.saveToken(account.token);
      // 2. 联网获取最新 Session
      final user = await api.getSession();

      // 3. ✅ 核心：更新 Provider 状态
      // 一旦这里设置了 User，Router 里的 redirect 逻辑就会自动识别为"已登录"，
      // 从而在 App 启动时直接跳转到 '/chat'
      container.read(currentUserProvider.notifier).setUser(user);

      logger.i("main: 自动登录成功！");
    }
  } catch (e) {
    logger.e("自动登录失败: $e");
    // 失败也没关系，currentUser 默认为 null，Router 会自动跳到 '/login'
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(), // ✅ 核心修改：不需要传参数了
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 监听路由 Provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter QQ',
      debugShowCheckedModeBanner: false,

      // ✅ 将路由配置委托给 GoRouter
      routerConfig: router,
    );
  }
}
