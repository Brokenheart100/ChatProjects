import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/screens/login_screen.dart';
import 'package:flutterchat/screens/register_screen.dart';
import 'package:flutterchat/screens/home_screen.dart'; // 我们将改造它
import 'package:flutterchat/screens/views/chat_view.dart';
import 'package:flutterchat/screens/views/contact_view.dart';

part 'router.g.dart';

// 全局 Navigator Key (用于弹窗等)
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(RouterRef ref) {
  // 监听用户登录状态，实现自动重定向
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/chat', // 默认进聊天页

    // 核心：重定向逻辑
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isGoingToAuth) {
        return '/login'; // 没登录，踢回登录页
      }
      if (isLoggedIn && isGoingToAuth) {
        return '/chat'; // 已登录，不准去登录页，踢回首页
      }
      return null; // 正常通行
    },

    routes: [
      // 1. 登录页
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // 2. 注册页
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 3. 首页 Shell (带侧边栏的路由)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // 返回我们要改造的 HomeScreen
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: 聊天
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatView(),
              ),
            ],
          ),
          // Tab 1: 联系人
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) => const ContactView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
