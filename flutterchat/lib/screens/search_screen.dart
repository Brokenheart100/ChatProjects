// 导入Flutter基础组件库
import 'package:flutter/material.dart';
// 导入窗口管理库，用于窗口拖动、最小化、最大化等系统级操作
import 'package:window_manager/window_manager.dart';

/// 搜索页面组件，继承StatefulWidget（有状态组件）
/// 支持窗口交互（拖动、关闭确认等）和加载动画效果
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  // 创建对应的状态管理类
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// 搜索页面的状态管理类
/// 混入WindowListener，用于监听窗口事件（焦点变化、关闭等）
class _SearchScreenState extends State<SearchScreen> with WindowListener {
  // 控制是否显示加载动画的状态变量（初始为true，显示加载）
  bool _isLoading = true;
  // 控制内容区域的透明度（初始为0.0，完全透明，用于淡入动画）
  double _opacity = 0.0;

  /// 初始化方法：组件创建时调用
  @override
  void initState() {
    super.initState();
    // 给窗口管理器添加当前实例作为监听器，用于接收窗口事件
    windowManager.addListener(this);

    // 模拟1秒的初始加载过程（可替换为真实数据加载逻辑）
    Future.delayed(const Duration(seconds: 1), () {
      // 检查组件是否仍在Widget树中（防止已销毁组件调用setState）
      if (mounted) {
        setState(() {
          _isLoading = false; // 关闭加载动画
        });
        // 延迟100毫秒触发内容淡入动画（让加载动画和淡入有时间间隔，更流畅）
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _opacity = 1.0; // 将透明度设为1.0，触发淡入效果
            });
          }
        });
      }
    });
  }

  /// 销毁方法：组件从Widget树移除时调用
  @override
  void dispose() {
    // 从窗口管理器移除监听器，防止内存泄漏
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 窗口获得焦点时的回调（WindowListener接口实现）
  @override
  void onWindowFocus() {
    if (mounted) {
      setState(() {}); // 刷新界面（确保焦点变化时UI状态正确）
    }
  }

  /// 窗口关闭时的回调（WindowListener接口实现）
  @override
  void onWindowClose() async {
    final currentContext = context;
    // 先允许窗口关闭（后续根据用户选择决定是否阻止）
    await windowManager.setPreventClose(false);
    if (!mounted) return; // 第一个保护
    // 显示关闭确认对话框
    final shouldClose = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2D2A), // 对话框背景色（深灰，与整体风格统一）
        title:
            const Text('确认关闭？', style: TextStyle(color: Colors.white)), // 标题文字
        actions: [
          // 取消按钮：返回false（不关闭窗口）
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消', style: TextStyle(color: Colors.white70))),
          // 关闭按钮：返回true（确认关闭）
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('关闭', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    // 如果用户选择不关闭，则阻止窗口关闭
    if (shouldClose != true) {
      await windowManager.setPreventClose(true);
    } else {
      // 否则执行关闭操作
      await windowManager.close();
    }
  }

  /// 构建页面UI的核心方法
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // 文本方向：从左到右
      child: Material(
        color: const Color(0xFF2E2D2A), // 基础背景色（深灰，防止白屏闪烁）
        child: Scaffold(
          backgroundColor: const Color(0xFF2E2D2A), // 页面背景色（与整体风格统一）
          body: Column(
            children: [
              _buildTitleBar(), // 构建可拖动的标题栏
              Expanded(
                child: _buildLoadingContent(), // 构建加载动画和内容区域（占满剩余空间）
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建加载动画和内容区域（根据加载状态动态切换）
  Widget _buildLoadingContent() {
    // 使用FutureBuilder处理异步加载状态（模拟2秒加载，可替换为真实API请求）
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)), // 模拟加载耗时
      builder: (context, snapshot) {
        // 加载中状态：显示旋转进度条和提示文字
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: const Color(0xFF2E2D2A), // 背景色与页面统一，避免白屏
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                children: [
                  // 圆形进度条（黄色调，匹配类似QQ的设计风格）
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFC9C960)),
                    strokeWidth: 3, // 进度条粗细
                  ),
                  const SizedBox(height: 16), // 间距
                  // 加载提示文字
                  const Text(
                    '正在加载...',
                    style: TextStyle(
                      color: Colors.white70, // 浅白色文字，与深色背景对比
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        // 加载错误状态（可选处理：当future返回错误时显示）
        else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64), // 错误图标
                const SizedBox(height: 16),
                const Text('加载失败',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                // 重试按钮：点击刷新状态（重新触发FutureBuilder）
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('重试',
                      style: TextStyle(color: Color(0xFFC9C960))),
                ),
              ],
            ),
          );
        }
        // 加载完成状态：显示内容并添加淡入动画
        else {
          return AnimatedOpacity(
            opacity: _opacity, // 透明度由状态变量控制（从0到1实现淡入）
            duration: const Duration(milliseconds: 500), // 淡入动画时长：0.5秒
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 搜索图标（半透明白色，与背景协调）
                  const Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  // 标题文字（白色粗体，突出显示）
                  const Text(
                    '综合搜索',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 辅助说明文字（浅白色，次要信息）
                  Text(
                    '窗口创建成功！\n（纯色 + 文字测试模式）',
                    textAlign: TextAlign.center, // 文字居中
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

  /// 构建可拖动的标题栏（包含窗口控制按钮）
  Widget _buildTitleBar() {
    // DragToMoveArea：使该区域支持鼠标拖动窗口（window_manager库提供）
    return DragToMoveArea(
      child: Container(
        height: 40, // 标题栏高度
        color: const Color(0xFF2E2D2A), // 标题栏背景色（与页面统一）
        child: Row(
          children: [
            const SizedBox(width: 16), // 左侧间距
            // 标题文字（浅白色，显示"综合搜索"）
            const Text(
              '综合搜索',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(), // 占位符，将按钮推到右侧
            // 最小化按钮
            IconButton(
              onPressed: () => windowManager.minimize(), // 调用窗口管理器的最小化方法
              icon: const Icon(Icons.remove, size: 16, color: Colors.white70),
            ),
            // 最大化/还原按钮
            IconButton(
              onPressed: () async {
                // 判断当前窗口是否最大化
                final isMax = await windowManager.isMaximized();
                if (isMax) {
                  windowManager.unmaximize(); // 还原窗口
                } else {
                  windowManager.maximize(); // 最大化窗口
                }
              },
              icon: const Icon(Icons.crop_square,
                  size: 16, color: Colors.white70),
            ),
            // 关闭按钮
            IconButton(
              onPressed: () => windowManager.close(), // 调用窗口管理器的关闭方法
              icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
