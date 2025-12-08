import 'dart:io'; // ✅ 1. 引入 IO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 2. 引入 ImagePicker
import 'package:flutterchat/screens/views/group_chat_view.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/providers/contact_provider.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final Set<String> _selectedUserIds = {};
  final TextEditingController _nameController = TextEditingController();

  // ✅ 3. 新增：存储选中的头像文件
  XFile? _avatarFile;

  bool _isCreating = false;

  // ✅ 4. 新增：选择图片的方法
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // 稍微压缩一下
      );
      if (pickedFile != null) {
        setState(() {
          _avatarFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("选择图片失败: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactListProvider);

    return Container(
      color: const Color(0xFF54514E),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 顶部标题栏 ---
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

          // --- ✅ 5. 新增：居中的头像选择器 ---
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF403E54),
                      border: Border.all(color: Colors.white24, width: 1),
                      image: _avatarFile != null
                          ? DecorationImage(
                              image: FileImage(File(_avatarFile!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _avatarFile == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white54, size: 30)
                        : null,
                  ),
                  if (_avatarFile != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6584FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- 群名输入框 ---
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

          // --- 成员列表 ---
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
      final apiService = ref.read(apiServiceProvider);

      // ✅ 6. 核心逻辑：如果选了图片，先上传
      String avatarObjectKey = '';
      if (_avatarFile != null) {
        // 使用 apiService 中已有的文件上传方法
        // 注意：这里我们假设 apiService 有 uploadFileAndGetObjectKey 方法
        // 如果没有，请参考 FileApi 补充
        try {
          avatarObjectKey =
              await apiService.uploadFileAndGetObjectKey(_avatarFile!);
        } catch (e) {
          throw "头像上传失败: $e";
        }
      }

      final newGroupId = const Uuid().v4();
      final groupName = _nameController.text;

      // 获取用于本地显示的完整 URL (如果上传了的话)
      final fullAvatarUrl = avatarObjectKey.isNotEmpty
          ? apiService.getFullAvatarUrl(avatarObjectKey)
          : '';

      // 7. 本地存库
      final newConv = Conversation(
        id: 0,
        uuid: newGroupId,
        recipientId: '',
        name: groupName,
        avatar: fullAvatarUrl, // ✅ 使用上传后的头像
        lastMessage: '群聊已创建',
        lastMessageAt: DateTime.now(),
        isGroup: true,
      );

      ref.read(objectBoxProvider).saveConversation(newConv);
      ref.read(conversationListProvider.notifier).addManualItem(newConv);

      if (mounted) {
        context.go('/chat');
      }

      // 8. 远程同步
      // ⚠️ 注意：你需要去修改 GroupApi 的 createGroup 方法，增加 avatarUrl 参数！
      await apiService.createGroup(
        id: newGroupId, // 传递 ID 参数
        groupName: groupName,
        memberIds: _selectedUserIds.toList(),
        avatarUrl: avatarObjectKey, // ✅ 传递 ObjectKey 给后端
      );
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
