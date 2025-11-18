import 'package:flutter/material.dart';
import 'package:flutterchat/models/auth_response.dart';
import 'package:flutterchat/services/account_service.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:window_manager/window_manager.dart';
import './screens/login_screen.dart'; // 引入登录屏幕
import './screens/register_screen.dart';
import 'screens/home_screen.dart'; // 引入注册屏幕

void main() async {
  // 确保 Flutter 和 window_manager 初始化
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 设置窗口选项，创建一个小巧、不可拉伸、居中的窗口
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    center: true, // 窗口居中
    backgroundColor: Colors.transparent, // 设置背景透明以显示圆角 (如果需要)
    skipTaskbar: false,
    windowButtonVisibility: false,
  );

  // 等待窗口准备好后显示
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  final apiService = ApiService();
  final accountService = AccountService();
  String initialRoute = '/login'; // 默认路由为登录页
  AuthResponse? authResponse;
  try {
    // 1. 查找被标记为“自动登录”的账户
    final accountToAutoLogin = await accountService.getAccountForAutoLogin();

    if (accountToAutoLogin != null) {
      logger.i("main: 找到自动登录账户: ${accountToAutoLogin.username}");
      // 2. 使用该账户的 Token 来恢复会话
      //    我们需要先将 token 保存到 ApiService 能读取的地方
      await apiService.saveToken(accountToAutoLogin.token);
      authResponse = await apiService.getSession();
      initialRoute = '/home';
      logger.i("main: 自动登录成功！");
    }
  } catch (e) {
    logger.w("main: 自动登录失败. 错误: $e");
    // 失败则保持默认路由 /login
  }
  runApp(MyApp(
    initialRoute: initialRoute,
    authResponse: authResponse,
  ));
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
      initialRoute: initialRoute, // 设置初始路由为登录屏幕
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) {
          // 尝试从路由参数获取用户信息，如果为 null (自动登录场景)，
          // 则使用我们从 main 函数传递过来的 authResponse
          final args =
              ModalRoute.of(context)?.settings.arguments ?? authResponse;
          return HomeScreen(authResponse: args as AuthResponse?);
        },
      },
    );
  }
}
