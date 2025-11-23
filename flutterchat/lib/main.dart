import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 引入 Riverpod
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 引入我们在上一节定义的 Provider
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:window_manager/window_manager.dart';
import './screens/login_screen.dart';
import './screens/register_screen.dart';
import 'screens/home_screen.dart';

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

  // --- Riverpod 初始化逻辑 ---
  // 创建一个容器，用于在 App 启动前操作 Provider 状态
  final container = ProviderContainer();

  // 虽然我们现在有了 ApiService 的 Provider，但在 main 函数这种
  // 极早期的初始化阶段，直接 new 一个实例来做检查也是没问题的，
  // 或者我们可以从容器里读取：final apiService = container.read(apiServiceProvider);
  final apiService = ApiService();
  final accountService = AccountService();

  String initialRoute = '/login';
  AuthResponse? authResponse;

  try {
    final accountService = container.read(accountServiceProvider);
    final account = await accountService.getAccountForAutoLogin();

    if (account != null) {
      final api = container.read(apiServiceProvider);
      await api.saveToken(account.token);
      final user = await api.getSession();
      container.read(currentUserProvider.notifier).setUser(user);
      initialRoute = '/home';
    }
  } catch (e) {
    print("自动登录失败: $e");
  }

  runApp(
    // 使用 UncontrolledProviderScope 将我们预配置好的 container 传递给 Flutter
    UncontrolledProviderScope(
      container: container,
      child: MyApp(
        initialRoute: initialRoute,
        // authResponse 其实不需要传了，因为已经在 Provider 里了，
        // 但为了兼容旧的 HomeScreen 构造函数，我们先传进去
        authResponse: authResponse,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final AuthResponse? authResponse;

  const MyApp({
    super.key,
    required this.initialRoute,
    this.authResponse,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QQ',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          // 如果路由参数为空，使用 main 传进来的
          final args =
              ModalRoute.of(context)?.settings.arguments ?? authResponse;
          // 注意：HomeScreen 内部现在应该优先使用 ref.watch(currentUserProvider)
          return HomeScreen(authResponse: args as AuthResponse?);
        },
      },
    );
  }
}
