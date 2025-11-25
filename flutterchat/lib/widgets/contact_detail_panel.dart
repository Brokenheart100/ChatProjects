import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/providers/conversation_provider.dart';
import 'package:go_router/go_router.dart';

class ContactDetailPanel extends ConsumerStatefulWidget {
  final Contact contact;

  const ContactDetailPanel({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<ContactDetailPanel> createState() => _ContactDetailPanelState();
}

class _ContactDetailPanelState extends ConsumerState<ContactDetailPanel> {
  String? _selectedGroup;
  final List<String> _groupOptions = ['我的好友', '家人', '同事'];

  @override
  void initState() {
    super.initState();
    // 初始化分组逻辑保持不变
    _updateSelectedGroup();
  }

  @override
  void didUpdateWidget(ContactDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contact != oldWidget.contact) {
      _updateSelectedGroup();
    }
  }

  void _updateSelectedGroup() {
    _selectedGroup = (widget.contact.groupName != null &&
            _groupOptions.contains(widget.contact.groupName))
        ? widget.contact.groupName
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color(0xFF54514E),
        child: ListView(
          padding: const EdgeInsets.all(30.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPersonalInfo(),
            const SizedBox(height: 20),
            _buildLevel(),
            const Divider(color: Colors.white10, height: 40),
            _buildInfoRow(Icons.edit_outlined, '备注', widget.contact.remark),
            _buildGroupDropdown(),
            _buildInfoRow(Icons.edit_note_outlined, '签名',
                widget.contact.signature ?? '(暂无签名)'),
            _buildInfoRow(Icons.star_outline, 'QQ空间', '', isArrow: true),
            const SizedBox(height: 20),
            _buildPhotoGrid(),
            const SizedBox(height: 50),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ... 中间大部分 UI 构建方法保持不变，请直接复制原来的 ...
  // 这里为了节省篇幅，我只列出修改了的地方，请你在实际操作时保留原来的 _buildHeader, _buildPersonalInfo 等方法

  Widget _buildGroupDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          const Text('好友分组',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGroup,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Microsoft YaHei'),
                dropdownColor: const Color(0xFF3E3C39),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGroup = newValue;
                  });
                },
                items:
                    _groupOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 必须保留 Header, PersonalInfo 等方法，直接从旧代码复制过来即可
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundImage: (widget.contact.avatarUrl != null &&
                  widget.contact.avatarUrl!.isNotEmpty)
              ? NetworkImage(widget.contact.avatarUrl!)
              : null,
          child: (widget.contact.avatarUrl == null ||
                  widget.contact.avatarUrl!.isEmpty)
              ? const Icon(Icons.person, size: 50, color: Colors.white54)
              : null,
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contact.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('QQ (暂无)',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                const Text('离线',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    if (widget.contact.gender == null &&
        widget.contact.age == null &&
        widget.contact.birthday == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.contact.gender != null) ...[
          Icon(widget.contact.gender == '男' ? Icons.male : Icons.female,
              color: Colors.blue, size: 16),
          Text(' ${widget.contact.gender}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
        if (widget.contact.age != null)
          Text('${widget.contact.age}岁',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        if (widget.contact.birthday != null)
          Text(widget.contact.birthday!,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        if (widget.contact.constellation != null)
          Text(widget.contact.constellation!,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildLevel() {
    return Row(
      children: const [
        Icon(Icons.sunny, color: Colors.orange, size: 18),
        Icon(Icons.sunny, color: Colors.orange, size: 18),
        Icon(Icons.nightlight_round, color: Colors.grey, size: 14),
        Icon(Icons.nightlight_round, color: Colors.grey, size: 14),
        Icon(Icons.star, color: Colors.yellow, size: 18),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isArrow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 15))),
          if (isArrow)
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('精选照片',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(),
      ],
    );
  }

  // 3. 核心修改：ActionButtons 使用 GoRouter 跳转
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton('分享'),
        const SizedBox(width: 12),
        _buildButton('音视频通话'),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // 1. 业务逻辑：在会话列表中选中该联系人
            // (createOrSelect 会更新 selectedConversationIndexProvider)
            ref
                .read(conversationListProvider.notifier)
                .createOrSelect(widget.contact);

            // 2. 路由跳转：切换到聊天 Tab
            // GoRouter 会自动识别这是一个 ShellRoute 分支切换
            context.go('/chat');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9C960),
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text('发消息'),
        ),
      ],
    );
  }

  Widget _buildButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E5C59),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Text(text),
    );
  }
}
