import 'package:flutter/material.dart';
import '../models/contact.dart';

// --- 核心改动 1: 将 Widget 转换为 StatefulWidget ---
class ContactDetailPanel extends StatefulWidget {
  final Contact contact;
  final ValueChanged<Contact>? onSendMessage;
  const ContactDetailPanel({
    super.key,
    required this.contact,
    this.onSendMessage, // --- 新增：构造函数参数 ---
  });

  @override
  State<ContactDetailPanel> createState() => _ContactDetailPanelState();
}

class _ContactDetailPanelState extends State<ContactDetailPanel> {
  // --- 核心改动 2: 将状态变量移入 State 类 ---
  String? _selectedGroup;
  final List<String> _groupOptions = ['我的好友', '家人', '同事'];
  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化状态，而不是在 build 方法中
    // _selectedGroup = widget.contact.groupName;
  }

  @override
  void didUpdateWidget(ContactDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件传入的 contact 对象发生变化时 (例如用户切换了选中的好友)，
    // 我们也需要更新 _selectedGroup
    if (widget.contact != oldWidget.contact) {
      _updateSelectedGroup();
    }
  }

  void _updateSelectedGroup() {
    // 如果 contact 的 groupName 存在于我们的选项中，就设为默认值，否则为 null
    _selectedGroup = (widget.contact.groupName != null &&
            _groupOptions.contains(widget.contact.groupName))
        ? widget.contact.groupName
        : null;
  }

  // --- 核心改动 3: 在 build 方法中，用 widget.contact 访问传入的数据 ---
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: const Color(0xFF54514E),
        // 使用 ListView 代替 Column，以获得自然的滚动效果
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 45,
          // 使用 NetworkImage 加载网络头像
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
            // 使用 name 属性
            Text(widget.contact.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // QQ 号码暂时用占位符
            const Text('QQ (暂无)',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                // 状态暂时用静态占位符
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

    // --- 核心修复：使用 Wrap 代替 Row ---
    return Wrap(
      spacing: 8.0, // 子组件之间的水平间距
      runSpacing: 4.0, // 行与行之间的垂直间距
      crossAxisAlignment: WrapCrossAlignment.center, // 让同一行的所有子组件垂直居中
      children: [
        if (widget.contact.gender != null) ...[
          Icon(widget.contact.gender == '男' ? Icons.male : Icons.female,
              color: Colors.blue, size: 16),
          Text(' ${widget.contact.gender}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          // 我们不再需要手动添加 Divider，间距由 spacing 控制
          // _buildDivider(),
        ],
        if (widget.contact.age != null) ...[
          Text('${widget.contact.age}岁',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          // _buildDivider(),
        ],
        if (widget.contact.birthday != null) ...[
          Text(widget.contact.birthday!,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          // _buildDivider(),
        ],
        if (widget.contact.constellation != null)
          Text(widget.contact.constellation!,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
    // ------------------------------------
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
            widget.onSendMessage?.call(widget.contact);
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

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('|', style: TextStyle(color: Colors.white30)),
      );
}
