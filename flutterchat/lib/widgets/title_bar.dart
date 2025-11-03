import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: const Color(0xFF3D3D3D),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage('assets/Image/30.jpg'),
            ),
            const SizedBox(width: 8),
            const Text(
              'A A A水果批发发哥',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const Spacer(),
            Row(
              children: [
                IconButton(
                  onPressed: () => windowManager.minimize(),
                  icon: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  onPressed: () => windowManager.maximize(),
                  icon: const Icon(
                    Icons.crop_square,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  onPressed: () => windowManager.close(),
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
