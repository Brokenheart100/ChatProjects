import 'package:flutter/material.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QQ',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // 设置初始路由为登录屏幕
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(), // <-- 添加主屏幕路由
      },
    );
  }
}
