import 'package:flutter/material.dart';
import 'package:flutterchat/models/auth_response.dart';
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
  String initialRoute = '/login'; // 默认路由为登录页
  AuthResponse? authResponse;
  try {
    // 3. 使用 await 来“暂停”执行，直到 getSession() 完成
    logger.i("main: 正在尝试自动登录...");
    authResponse = await apiService.getSession();

    // 4. 如果上面的 await 没有抛出异常，说明成功了，我们才修改路由
    initialRoute = '/home';
    logger.i("main: 自动登录成功！初始路由设置为 /home");
  } catch (e) {
    // 5. 如果 getSession 失败，catch 块会捕获异常
    initialRoute = '/login';
    logger.w("main: 自动登录失败，初始路由设置为 /login. 错误: $e");
    // 这里我们什么都不做，让应用正常进入登录页
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
