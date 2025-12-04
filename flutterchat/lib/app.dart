import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/router.dart';
import 'package:window_manager/window_manager.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FlutterChat',
      debugShowCheckedModeBanner: false,

      // 路由配置
      routerConfig: router,

      // 主题配置
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF333333),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6584FE),
        ),
      ),
    );
  }
}
