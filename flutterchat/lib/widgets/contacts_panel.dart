// lib/widgets/contacts_panel.dart

import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import 'contact_detail_panel.dart'; // <-- Import the new detail panel

class ContactsPanel extends StatefulWidget {
  final List<ContactGroup> contactGroups;

  const ContactsPanel({super.key, required this.contactGroups});

  @override
  State<ContactsPanel> createState() => _ContactsPanelState();
}

class _ContactsPanelState extends State<ContactsPanel> {
  int _selectedTabIndex = 0;
  Contact? _selectedContact;
  final Set<String> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side: Contacts List (this is correct)
        _buildContactsList(),

        // --- FIX: Conditionally show detail panel or placeholder ---
        _selectedContact == null
            ? _buildPlaceholder()
            : ContactDetailPanel(contact: _selectedContact!),
      ],
    );
  }

  Widget _buildContactsList() {
    return Container(
      width: 280,
      color: const Color(0xFF474542),
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A5855),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '搜索',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: Colors.white54,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A5855),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white54),
                ),
              ],
            ),
          ),
          // Friend Manager Button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5A5855),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      '好友管理器',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildNotificationTile('好友通知'),
          _buildNotificationTile('群通知'),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Divider(color: Colors.white10, height: 1),
          ),

          _buildToggle(),

          // Contact Groups List
          Expanded(
            child: ListView.builder(
              itemCount: widget.contactGroups.length,
              itemBuilder: (context, index) {
                final group = widget.contactGroups[index];
                final isExpanded = _expandedGroups.contains(group.name);
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        color: Colors.white54,
                        size: 20,
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        group.countDisplay,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      dense: true,
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedGroups.remove(group.name);
                          } else {
                            _expandedGroups.add(group.name);
                          }
                        });
                      },
                    ),
                    if (isExpanded)
                      ...group.contacts
                          .map((contact) => _buildContactTile(contact)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    bool isSelected = _selectedContact == contact;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContact = contact;
        });
      },
      child: Container(
        color: isSelected ? const Color(0xFF5A5855) : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 8,
        ), // Indent a bit more
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(contact.avatar),
            ),
            const SizedBox(width: 12),
            // Use Expanded to prevent overflow with long names/signatures
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.remark,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        contact.statusIcon,
                        color: contact.statusIconColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      // Use Expanded here as well for the signature
                      Expanded(
                        child: Text(
                          '[${contact.statusText}] ${contact.signature}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white54,
        size: 20,
      ),
      dense: true,
      onTap: () {},
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF474542),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [_buildToggleTab('好友', 0), _buildToggleTab('群聊', 1)],
        ),
      ),
    );
  }

  Widget _buildToggleTab(String text, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5A5855) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Expanded(
      child: Container(
        color: const Color(0xFF54514E),
        child: const Center(
          child: Icon(Icons.flutter_dash, size: 120, color: Color(0x1F000000)),
        ),
      ),
    );
  }
}
