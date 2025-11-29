import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterchat/providers/group_detail_provider.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';

class GroupSettingsScreen extends ConsumerWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupDetailProvider(groupId));

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("群组信息"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (members) {
          return Column(
            children: [
              // 1. 群成员网格 (类似微信)
              Container(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, // 一行5个
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  // 显示成员 + 一个“添加”按钮
                  itemCount: members.length + 1,
                  itemBuilder: (context, index) {
                    if (index == members.length) {
                      // 最后一个是添加按钮
                      return Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.add, color: Colors.white70),
                          ),
                        ],
                      );
                    }

                    final member = members[index];
                    return Column(
                      children: [
                        CustomCircleAvatar(
                            avatarUrl: member.avatarUrl, radius: 24),
                        const SizedBox(height: 4),
                        Text(
                          member.username,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    );
                  },
                ),
              ),

              const Spacer(),

              // 2. 退出群聊按钮
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      final success = await ref
                          .read(groupDetailProvider(groupId).notifier)
                          .leaveGroup();
                      if (success && context.mounted) {
                        // 退群成功，回到首页（此时列表里的群应该已经删除了）
                        context.go('/chat');
                      }
                    },
                    child: const Text("退出群聊",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
