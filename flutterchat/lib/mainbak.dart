// lib/main.dart
import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart'; // 引入新的搜索屏幕

// 辅助函数：解析窗口参数（从字符串解析 JSON）
Map<String, dynamic>? parseArguments(String? arguments) {
  if (arguments == null || arguments.isEmpty) return null;
  try {
    return jsonDecode(arguments) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('解析窗口参数失败: $e');
    return null;
  }
}

Future<void> main() async {
  // 注意：main() 无需 List<String> args 参数，新 API 通过 WindowController 获取
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 获取当前窗口控制器和参数
  final windowController = await WindowController.fromCurrentEngine();
  final arguments = parseArguments(windowController.arguments);

  // 根据 window_type 配置并显示窗口
  if (arguments?['window_type'] == 'search') {
    // 搜索子窗口配置
    const WindowOptions options = WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(600, 400),
      center: true,
      titleBarStyle: TitleBarStyle.normal, // 搜索窗口显示标题栏
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setTitle('综合搜索');
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(const SearchScreen()); // 运行搜索 UI
  } else {
    // 主窗口配置
    const WindowOptions options = WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(900, 600),
      center: true,
      title: 'Flutter QQ',
      titleBarStyle: TitleBarStyle.hidden, // 主窗口隐藏标题栏
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Microsoft YaHei',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const HomeScreen(),
    );
  }
}
