import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/groups_provider/group_management_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/providers/services_provider.dart';

class GroupSettingsScreen extends ConsumerWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 2. 使用正确的 Provider 名称: groupManagementProvider
    final groupAsync = ref.watch(groupManagementProvider(groupId));
    final api = ref.read(apiServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF363636),
      appBar: AppBar(
        title: const Text("群设置", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child:
                Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (group) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. 群头像和名字
              Center(
                child: Column(
                  children: [
                    CustomCircleAvatar(avatarUrl: group.avatar, radius: 40),
                    const SizedBox(height: 10),
                    Text(group.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("群号: ${group.id}",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. 修改群名入口
              ListTile(
                tileColor: const Color(0xFF4A4A4A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title:
                    const Text("群聊名称", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.edit, color: Colors.white54),
                onTap: () => _showEditNameDialog(context, ref, group.name),
              ),

              const SizedBox(height: 20),

              // 3. 成员网格
              Text("群成员 (${group.memberCount}人)",
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                // ✅ 3. 修复：使用 group.members.length
                itemCount: group.members.length + 1,
                itemBuilder: (ctx, index) {
                  // 如果是最后一项，显示添加按钮
                  if (index == group.members.length) {
                    return _buildAddButton();
                  }
                  // ✅ 4. 修复：使用 group.members[index]
                  final m = group.members[index];

                  return Column(
                    children: [
                      CustomCircleAvatar(
                          avatarUrl: api.getFullAvatarUrl(m.avatarUrl),
                          radius: 22),
                      const SizedBox(height: 4),
                      Text(m.nickname,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis)
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // 4. 退出群聊按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    // ✅ 5. 修复：使用 groupManagementProvider
                    final success = await ref
                        .read(groupManagementProvider(groupId).notifier)
                        .leaveGroup();
                    if (success && context.mounted) {
                      context.go('/chat');
                    }
                  },
                  child:
                      const Text("退出群聊", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF3D3D3D),
              title: const Text("修改群名", style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("取消",
                        style: TextStyle(color: Colors.white54))),
                TextButton(
                    onPressed: () {
                      // ✅ 6. 修复：使用 groupManagementProvider
                      ref
                          .read(groupManagementProvider(groupId).notifier)
                          .updateName(controller.text);
                      Navigator.pop(ctx);
                    },
                    child: const Text("保存",
                        style: TextStyle(color: Color(0xFF6584FE)))),
              ],
            ));
  }

  Widget _buildAddButton() {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white30),
              shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        const Text("邀请", style: TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
