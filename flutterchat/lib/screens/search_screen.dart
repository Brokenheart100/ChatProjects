import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // 保留：支持拖动和事件

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this); // 保留：窗口监听
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // WindowListener 覆盖：处理焦点和关闭
  @override
  void onWindowFocus() {
    if (mounted) setState(() {}); // 简单刷新
  }

  @override
  void onWindowClose() async {
    await windowManager.setPreventClose(false);
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2D2A),
        title: const Text('确认关闭？', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消', style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('关闭', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldClose != true) {
      await windowManager.setPreventClose(true);
    } else {
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF2E2D2A), // 深灰背景，防白屏
        child: Scaffold(
          backgroundColor: const Color(0xFF2E2D2A),
          body: Column(
            children: [
              _buildTitleBar(), // 标题栏不变
              Expanded(
                child: _buildLoadingContent(), // 新增：加载内容构建器
              ),
            ],
          ),
        ),
      ),
    );
  }

// 新增：构建加载动画 + 内容
  Widget _buildLoadingContent() {
    return FutureBuilder(
      future: Future.delayed(
          const Duration(seconds: 2)), // 模拟 2 秒加载（可替换为真实 Future，如 API）
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 加载动画阶段：纯色背景 + 旋转圈 + 提示
          return Container(
            color: const Color(0xFF2E2D2A), // 确保无白屏
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    // 加载动画：黄色调匹配 QQ
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFC9C960)),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '正在加载...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // 错误处理（可选）
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text('加载失败',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                TextButton(
                  onPressed: () => setState(() {}), // 重试
                  child: const Text('重试',
                      style: TextStyle(color: Color(0xFFC9C960))),
                ),
              ],
            ),
          );
        } else {
          // 内容加载完成：淡入原内容
          return AnimatedOpacity(
            opacity: 0.0, // 起始透明
            duration: const Duration(milliseconds: 500), // 0.5 秒淡入
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '综合搜索',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '窗口创建成功！\n（纯色 + 文字测试模式）',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // 保留：可拖动标题栏
  Widget _buildTitleBar() {
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: const Color(0xFF2E2D2A),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              '综合搜索',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
            ),
            IconButton(
              onPressed: () async {
                final isMax = await windowManager.isMaximized();
                if (isMax) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              icon: const Icon(Icons.crop_square,
                  size: 16, color: Colors.white70),
            ),
            IconButton(
              onPressed: () => windowManager.close(),
              icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
