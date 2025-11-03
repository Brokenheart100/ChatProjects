// lib/widgets/contact_detail_panel.dart

import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactDetailPanel extends StatelessWidget {
  final Contact contact;
  const ContactDetailPanel({super.key, required this.contact});

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
            _buildInfoRow(Icons.edit_outlined, '备注', contact.remark),
            _buildInfoRow(
              Icons.group_outlined,
              '好友分组',
              contact.groupName,
              isDropdown: true,
            ),
            _buildInfoRow(Icons.edit_note_outlined, '签名', contact.signature),
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

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(radius: 45, backgroundImage: AssetImage(contact.avatar)),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'QQ ${contact.qqNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  contact.statusIcon,
                  color: contact.statusIconColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  contact.statusText,
                  style: TextStyle(
                    color: contact.statusIconColor,
                    fontSize: 14,
                  ),
                ),
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
        Icon(
          contact.gender == '男' ? Icons.male : Icons.female,
          color: Colors.blue,
          size: 16,
        ),
        Text(
          ' ${contact.gender}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        _buildDivider(),
        Text(
          '${contact.age}岁',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        _buildDivider(),
        Text(
          contact.birthday,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        _buildDivider(),
        Text(
          contact.constellation,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isArrow = false,
    bool isDropdown = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          if (isArrow)
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          if (isDropdown)
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '精选照片',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: contact.photos
              .map(
                (path) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.asset(
                    path,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
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
