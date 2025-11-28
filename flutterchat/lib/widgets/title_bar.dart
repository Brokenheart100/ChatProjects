import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 用于获取 currentUser 和 apiService
import 'package:flutterchat/widgets/custom_circle_avatar.dart'; // 用于显示头像

class CustomTitleBar extends ConsumerWidget implements PreferredSizeWidget {
  // 我们不再需要从外部传入 avatarUrl，直接在内部通过 Provider 获取
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听当前登录用户
    final currentUser = ref.watch(currentUserProvider);
    final apiService = ref.read(apiServiceProvider);

    // 2. 获取真实头像 URL
    final fullAvatarUrl = currentUser != null
        ? apiService.getFullAvatarUrl(currentUser.avatarUrl)
        : null;

    return DragToMoveArea(
      child: Container(
        height: 40,
        color: const Color(0xFF3D3D3D),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 3. 使用项目统一的 CustomCircleAvatar
            CustomCircleAvatar(
              avatarUrl: fullAvatarUrl,
              radius: 12, // 这里的半径对应 height=24
            ),
            const SizedBox(width: 8),

            // 4. 显示真实用户名
            Text(
              currentUser?.username ?? '未登录',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),

            const Spacer(),

            // 窗口控制按钮
            Row(
              children: [
                IconButton(
                  onPressed: () => windowManager.minimize(),
                  tooltip: "最小化",
                  icon: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                  tooltip: "最大化/还原",
                  icon: const Icon(
                    Icons.crop_square,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  onPressed: () => windowManager.close(),
                  tooltip: "关闭",
                  hoverColor: Colors.red, // 关闭按钮悬停变红
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
