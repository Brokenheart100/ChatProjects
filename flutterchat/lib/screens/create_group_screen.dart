import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/contact_provider.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/screens/views/chat_view.dart'; // ✅ 引入 chatSubStateProvider
import 'package:flutterchat/widgets/custom_circle_avatar.dart';

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
          // 头部
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
              // 取消按钮
              TextButton(
                onPressed: () {
                  // ✅ 核心修复：切换回普通聊天视图
                  ref.read(chatSubStateProvider.notifier).state = ChatSubState.normal;
                },
                child:
                    const Text("取消", style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(width: 16),
              // 创建按钮
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

          // 群名称输入
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

          // 好友列表
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

      // 3. 写入本地库
      ref.read(objectBoxProvider).saveConversation(newConv);

      // 4. 更新列表
      ref.read(conversationListProvider.notifier).addManualItem(newConv);

      // 5. ✅ 核心修复：切换 UI 状态
      // 告诉 ChatView：别显示 CreateGroupScreen 了，显示 ChatPanel 吧
      ref.read(chatSubStateProvider.notifier).state = ChatSubState.normal;

      // 6. 后台调用 API
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
        setState(() => _isCreating = false);
      }
    }
  }
}