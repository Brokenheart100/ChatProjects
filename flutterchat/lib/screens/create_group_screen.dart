import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/screens/views/group_chat_view.dart';
import 'package:go_router/go_router.dart'; // ✅ 引入 GoRouter
import 'package:uuid/uuid.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/contact_provider.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
// 引入 GroupListView 中定义的局部状态 Provider

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final Set<String> _selectedUserIds = {};
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactListProvider);

    return Container(
      color: const Color(0xFF54514E),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "发起群聊",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // ✅ 修复：点击取消时，重置 GroupListView 的内部状态，回到列表视图
                  // (如果你是在 /groups 路由下嵌入显示的)
                  ref.read(groupChatSubStateProvider.notifier).state =
                      GroupChatSubState.normal;
                },
                child:
                    const Text("取消", style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _selectedUserIds.isEmpty ||
                        _nameController.text.isEmpty ||
                        _isCreating
                    ? null
                    : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6584FE),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("创建", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "群聊名称",
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6584FE))),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 30),
          const Text("选择群成员",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("加载失败: $err")),
              data: (groups) {
                final myFriends = groups
                    .expand((g) => g.name == '我的好友' ? g.contacts : [])
                    .toList();

                if (myFriends.isEmpty) {
                  return const Center(
                      child: Text("没有好友",
                          style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  itemCount: myFriends.length,
                  itemBuilder: (context, index) {
                    final contact = myFriends[index];
                    final isSelected = _selectedUserIds.contains(contact.id);

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: const Color(0xFF6584FE),
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      title: Text(contact.name,
                          style: const TextStyle(color: Colors.white)),
                      secondary:
                          CustomCircleAvatar(avatarUrl: contact.avatarUrl),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(contact.id);
                          } else {
                            _selectedUserIds.remove(contact.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final newGroupId = const Uuid().v4();
      final groupName = _nameController.text;

      final newConv = Conversation(
        id: 0,
        uuid: newGroupId,
        recipientId: '',
        name: groupName,
        avatar: '',
        lastMessage: '群聊已创建',
        lastMessageAt: DateTime.now(),
        isGroup: true,
      );

      ref.read(objectBoxProvider).saveConversation(newConv);
      ref.read(conversationListProvider.notifier).addManualItem(newConv);

      // ✅ 核心修复：创建成功后，直接跳转到 /chat 路由
      // GoRouter 会自动切换左侧导航到 Index 0，并显示会话列表（新群已在置顶）
      if (mounted) {
        context.go('/chat');
      }

      ref
          .read(apiServiceProvider)
          .createGroup(
            newGroupId,
            groupName,
            _selectedUserIds.toList(),
          )
          .catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("同步服务器失败: $e"), backgroundColor: Colors.orange),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("创建失败: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
