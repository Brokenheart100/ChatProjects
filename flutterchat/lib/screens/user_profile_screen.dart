import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
// 简单起见，这里直接用 ApiService，也可以封装 UserProvider
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/models/user_search_result.dart';

final userProfileProvider =
    FutureProvider.family<UserSearchResult, String>((ref, userId) async {
  return ref
      .read(apiServiceProvider)
      .searchUsers(userId)
      .then((list) => list.first); // 临时用 search 模拟
});

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      appBar: AppBar(
          backgroundColor: Colors.transparent, title: const Text("详细资料")),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("加载失败: $err")),
        data: (user) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCircleAvatar(avatarUrl: user.avatarUrl, radius: 50),
              const SizedBox(height: 20),
              Text(user.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("ID: ${user.userId}",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // 如果是从通讯录点进来的，点击发消息会跳到 /chat
                  // 如果是从聊天点进来的，这个按钮可能不需要，或者是“清除记录”
                  context.go('/chat');
                  // 这里还需要通知 ConversationList 选中这个会话
                },
                child: const Text("发消息"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
