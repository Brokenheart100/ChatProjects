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

// 设置当前仓库走代理配置
// git config http.proxy http://127.0.0.1:7897
// git config https.proxy http://127.0.0.1:7897

// 全局 Navigator Key (用于弹窗等)
// 定义一个全局的NavigatorState键，用于根导航器。这允许在应用程序的任何地方访问根导航器，例如用于显示全局对话框或Snackbar。
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 定义一个全局的NavigatorState键，用于Shell导航器。这用于管理带有分支的嵌套导航结构，例如底部导航栏或侧边栏。
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// 使用Riverpod的@riverpod注解创建一个Provider，用于提供GoRouter实例。
// 这个Provider允许在应用程序中轻松访问和监听路由器的变化。
@riverpod
GoRouter router(RouterRef ref) {
  // 监听用户登录状态，实现自动重定向
  // 从Riverpod的currentUserProvider中获取当前用户状态。这是一个可监听的Provider，用于跟踪用户是否登录。
  final currentUser = ref.watch(currentUserProvider);

  // 创建并返回GoRouter实例，这是go_router包的核心，用于管理Flutter应用程序的路由。
  return GoRouter(
    // 设置根导航器的键，用于处理顶级导航事件。
    navigatorKey: _rootNavigatorKey,

    // 设置初始位置为'/chat'，应用程序启动时默认导航到聊天页面。
    initialLocation: '/chat', // 默认进聊天页

    // 核心：重定向逻辑
    // 定义重定向函数，用于根据用户状态动态重定向路由。
    // 这个函数在每次路由变化时被调用，以确保用户只能访问允许的页面。
    redirect: (context, state) {
      // 检查用户是否已登录：如果currentUser不为null，则视为已登录。
      final isLoggedIn = currentUser != null;

      // 检查当前目标路径是否是认证相关页面（登录或注册）。
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // 如果用户未登录且目标不是认证页面，则重定向到登录页面，防止未授权访问。
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login'; // 没登录，踢回登录页
      }

      // 如果用户已登录但试图访问认证页面，则重定向到聊天页面，防止已登录用户访问登录/注册页。
      if (isLoggedIn && isGoingToAuth) {
        return '/chat'; // 已登录，不准去登录页，踢回首页
      }

      // 如果以上条件都不满足，则不进行重定向，允许正常导航。
      return null; // 正常通行
    },

    // 定义路由列表，这是GoRouter的核心配置，指定所有可访问的路径及其对应的构建器。
    routes: [
      // 1. 登录页
      // 定义'/login'路径的路由，使用LoginScreen作为构建器。
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 2. 注册页
      // 定义'/register'路径的路由，使用RegisterScreen作为构建器。
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 3. 首页 Shell (带侧边栏的路由)
      // 使用StatefulShellRoute.indexedStack创建一个带有分支的Shell路由。
      // 这允许创建一个带有多个分支的嵌套导航结构，例如使用IndexedStack来切换不同视图，而不破坏状态。
      // 适用于带有底部导航栏或侧边栏的布局。
      StatefulShellRoute.indexedStack(
        // 构建器函数返回HomeScreen widget，并传入navigationShell，用于管理分支切换。
        builder: (context, state, navigationShell) {
          // 返回我们要改造的 HomeScreen
          return HomeScreen(navigationShell: navigationShell);
        },

        // 定义分支列表，每个分支代表一个独立的导航栈。
        branches: [
          // Tab 0: 聊天
          // 第一个分支：聊天视图。
          StatefulShellBranch(
            routes: [
              // 定义'/chat'路径的路由，使用ChatView作为构建器。
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatView(),
              ),
            ],
          ),

          // Tab 1: 联系人
          // 第二个分支：联系人视图。
          StatefulShellBranch(
            routes: [
              // 定义'/contacts'路径的路由，使用ContactView作为构建器。
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
