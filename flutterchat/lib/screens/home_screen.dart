import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/widgets/left_nav_rail.dart';
import 'package:flutterchat/widgets/title_bar.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/services/logger_service.dart';

// 这个 Provider 需要保留，因为 ContactView 还需要用到它来在右侧显示详情
final selectedContactProvider = StateProvider<Contact?>((ref) => null);

class HomeScreen extends ConsumerWidget {
  // 接收 GoRouter 传来的 navigationShell
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // 防御性代码：如果未登录，显示加载或空页面（Router 的 redirect 会负责跳转）
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
          // 顶部标题栏 (全局共有)
          CustomTitleBar(avatarUrl: fullAvatarUrl),

          Expanded(
            child: Row(
              children: [
                // 左侧导航栏
                LeftNavRail(
                  // 当前选中项由 GoRouter 的 Shell 决定
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    // 核心：告诉 GoRouter 切换分支
                    navigationShell.goBranch(
                      index,
                      // 支持点击当前 Tab 回到初始状态
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  avatarUrl: fullAvatarUrl,
                  // 将 context 和 ref 传递给 _logout 方法
                  onLogout: () => _logout(context, ref),
                ),

                // 右侧内容 (由 GoRouter 自动填充 ChatView 或 ContactView)
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 登出逻辑：必须接收 context 和 ref，因为 ConsumerWidget 没有这些成员变量
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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

      // 1. 调用 API 注销
      await ref.read(apiServiceProvider).logout();

      // 2. 清除全局用户状态
      // Router 的 redirect 逻辑会自动检测到 currentUser 变空，并跳转到 /login
      ref.read(currentUserProvider.notifier).clear();
    }
  }
}
