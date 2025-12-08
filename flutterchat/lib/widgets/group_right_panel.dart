import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/providers/groups_provider/group_management_provider.dart';
import 'package:flutterchat/providers/services_provider.dart'; // 用于 apiService 获取头像
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/models/group_detail.dart';

class GroupRightPanel extends ConsumerWidget {
  final String groupId;

  const GroupRightPanel({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupManagementProvider(groupId));
    final api = ref.read(apiServiceProvider);

    return Container(
      width: 240, // 固定宽度
      color: const Color(0xFF2E2E2E), // 深色背景，比聊天区稍深
      child: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text("加载失败", style: TextStyle(color: Colors.grey))),
        data: (group) {
          return Column(
            children: [
              // 1. 群公告区域
              _buildAnnouncementSection(group),

              const Divider(height: 1, color: Colors.white10),

              // 2. 群成员头部
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text("群聊成员 ${group.memberCount}",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.search, color: Colors.white54, size: 18),
                  ],
                ),
              ),

              // 3. 成员列表
              Expanded(
                child: ListView.builder(
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final member = group.members[index];
                    // 假设 Role: 2=群主, 1=管理员, 0=成员
                    final isOwner = member.role == 2;
                    final isAdmin = member.role == 1;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      leading: CustomCircleAvatar(
                        avatarUrl: api.getFullAvatarUrl(member.avatarUrl),
                        radius: 16,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.nickname.isNotEmpty
                                  ? member.nickname
                                  : "用户",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOwner || isAdmin) ...[
                            const SizedBox(width: 4),
                            _buildRoleBadge(
                                isOwner ? "群主" : "管理员",
                                isOwner
                                    ? const Color(0xFFF4A100)
                                    : const Color(0xFF0052D9)),
                          ]
                        ],
                      ),
                      // subtitle: Text("Lv.100", style: TextStyle(color: Colors.grey, fontSize: 10)), // 如果有等级
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementSection(GroupDetail group) {
    return ExpansionTile(
      title: const Text("群公告",
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      initiallyExpanded: true,
      collapsedIconColor: Colors.white54,
      iconColor: Colors.white70,
      shape: const Border(), // 去除边框
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.announcement.isNotEmpty ? group.announcement : "暂无公告",
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.4),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(77),
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9),
      ),
    );
  }
}
