// lib/widgets/contact_detail_panel.dart

import 'package:flutter/material.dart';
import '../models/contact.dart';
// 假设您已经将 PlaceholderAvatar 提取到了单独的文件
// import 'placeholder_avatar.dart';

// --- 核心改动 1: 将 Widget 转换为 StatefulWidget ---
class ContactDetailPanel extends StatefulWidget {
  final Contact contact;
  const ContactDetailPanel({super.key, required this.contact});

  @override
  State<ContactDetailPanel> createState() => _ContactDetailPanelState();
}

class _ContactDetailPanelState extends State<ContactDetailPanel> {
  // --- 核心改动 2: 将状态变量移入 State 类 ---
  String? _selectedGroup;

  final List<String> _groupOptions = [
    '《高中美男团》',
    '【ε-世界线】',
    '【β-世界线】',
    '家人',
    '同事',
  ];

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化状态，而不是在 build 方法中
    _selectedGroup = widget.contact.groupName;
  }

  // --- 核心改动 3: 在 build 方法中，用 widget.contact 访问传入的数据 ---
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color(0xFF54514E),
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPersonalInfo(),
            const SizedBox(height: 20),
            _buildLevel(),
            const Divider(color: Colors.white10, height: 40),
            _buildInfoRow(Icons.edit_outlined, '备注', widget.contact.remark),

            // --- 核心改动 4: 调用下拉框构建方法 ---
            _buildGroupDropdown(),

            _buildInfoRow(
                Icons.edit_note_outlined, '签名', widget.contact.signature),
            _buildInfoRow(Icons.star_outline, 'QQ空间', '', isArrow: true),
            const SizedBox(height: 20),
            _buildPhotoGrid(),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // --- 核心改动 5: 实现下拉框构建方法，并正确使用 setState ---
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
                  // setState 在 State 类中是合法的，它会通知 Flutter 重建 UI
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

  // --- 所有其他方法现在都使用 widget.contact 来访问数据 ---

  Widget _buildHeader() {
    return Row(
      children: [
        // 假设您已经在使用 PlaceholderAvatar
        // PlaceholderAvatar(text: widget.contact.name, radius: 45, fontSize: 32),
        CircleAvatar(
            radius: 45, backgroundImage: AssetImage(widget.contact.avatar)),
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
            Text('QQ ${widget.contact.qqNumber}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(widget.contact.statusIcon,
                    color: widget.contact.statusIconColor, size: 16),
                const SizedBox(width: 6),
                Text(widget.contact.statusText,
                    style: TextStyle(
                        color: widget.contact.statusIconColor, fontSize: 14)),
              ],
            ),
          ],
        ),
        const Spacer(),
        Column(
          children: const [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 20),
            SizedBox(height: 4),
            Text('1010', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Row(
      children: [
        Icon(widget.contact.gender == '男' ? Icons.male : Icons.female,
            color: Colors.blue, size: 16),
        Text(' ${widget.contact.gender}',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        _buildDivider(),
        Text('${widget.contact.age}岁',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        _buildDivider(),
        Text(widget.contact.birthday,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        _buildDivider(),
        Text(widget.contact.constellation,
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
    if (widget.contact.photos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('精选照片',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: widget.contact.photos
              .map((path) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.asset(path,
                        width: 60, height: 60, fit: BoxFit.cover),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton('分享'),
        const SizedBox(width: 12),
        _buildButton('音视频通话'),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {},
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

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('|', style: TextStyle(color: Colors.white30)),
      );
}
