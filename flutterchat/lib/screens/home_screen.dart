import 'dart:async'; // 引入 async 用于定时器
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ✅ 引入在线状态 Provider
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/widgets/left_nav_rail.dart';
import 'package:flutterchat/widgets/title_bar.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/services/logger_service.dart';

// 这个 Provider 需要保留，因为 ContactView 还需要用到它来在右侧显示详情
final selectedContactProvider = StateProvider<Contact?>((ref) => null);

// 1. 改为 ConsumerStatefulWidget 以支持 initState
class HomeScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _heartbeatTimer;
  @override
  void initState() {
    super.initState();

    // 🧪🧪🧪 【测试代码】模拟好友上线 🧪🧪🧪
    // 延迟 3 秒，强行把某个好友设为在线
    // Future.delayed(const Duration(seconds: 3), () {
    //   // ⚠️ 请把这里的 ID 换成你数据库里好友 (test2) 的真实 UserID
    //   // 你可以在联系人列表的日志里找到这个 ID
    //   const friendId = "abca6efd-1a66-465f-9a0b-692d0a939d06";

    //   if (mounted) {
    //     logger.i("🧪 [TEST] 模拟好友上线: $friendId");
    //     // 强制设置在线状态
    //     ref.read(onlineUsersProvider.notifier).setOnlineBatch([friendId]);
    //   }
    // });
    // 🧪🧪🧪 测试代码结束 🧪🧪🧪
    _reportOnline();

    // 2. 启动心跳：每 30 秒上报一次在线状态
    // (具体时间间隔取决于你后端的过期时间配置，建议设置为过期时间的一半)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _reportOnline();
    });
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(apiServiceProvider).reportOnline();
    });
  }

  void _reportOnline() {
    // 简单的错误捕获，防止网络断开时 crash
    ref.read(apiServiceProvider).reportOnline().catchError((e) {
      logger.w("心跳上报失败: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF363636),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fullAvatarUrl =
        ref.read(apiServiceProvider).getFullAvatarUrl(currentUser.avatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      body: Column(
        children: [
          // 顶部标题栏
          const CustomTitleBar(),

          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                LeftNavRail(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    widget.navigationShell.goBranch(
                      index,
                      initialLocation:
                          index == widget.navigationShell.currentIndex,
                    );
                  },
                  avatarUrl: fullAvatarUrl,
                  onLogout: () => _logout(),
                ),

                // 右侧内容
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    logger.i("🚪 [HomeScreen] 用户点击登出按钮");
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D3D3D),
        title: const Text('确认登出', style: TextStyle(color: Colors.white)),
        content:
            const Text('确定要退出登录吗？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      logger.w("👋 [HomeScreen] 执行登出逻辑...");
      await ref.read(apiServiceProvider).logout();
      ref.read(currentUserProvider.notifier).clear();
    }
  }
}
