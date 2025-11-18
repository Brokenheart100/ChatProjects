import 'package:flutter/material.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/widgets/custom_circle_avatar.dart';
import 'package:flutterchat/widgets/custom_search_field.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import 'contact_detail_panel.dart'; // <-- Import the new detail panel

class ContactsPanel extends StatefulWidget {
  final ValueChanged<Contact> onContactSelected;
  final VoidCallback? onAddFriend;
  final VoidCallback? onNavigateToFriendRequests;
  final String? selectedContactId;

  const ContactsPanel({
    super.key,
    required this.onContactSelected,
    this.onAddFriend,
    this.onNavigateToFriendRequests,
    this.selectedContactId,
  });

  @override
  State<ContactsPanel> createState() => _ContactsPanelState();
}

class _ContactsPanelState extends State<ContactsPanel> {
  int _selectedTabIndex = 0;
  Contact? _selectedContact;
  List<ContactGroup> _contactGroups = [];
  final _apiService = ApiService();
  bool _isLoading = true;
  int _pendingRequestCount = 0;
  final Set<String> _expandedGroups = {'我的好友'}; // 默认展开

  @override
  void initState() {
    super.initState();
    // _loadFriends(); // 在初始化时加载好友数据
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getFriends(),
        _apiService.getPendingFriendRequestsCount(),
      ]);

      final friendsFromApi = results[0] as List<UserSearchResult>;
      final count = results[1] as int;

      final friendsGroup = ContactGroup(name: "我的好友", contacts: []);
      for (var friend in friendsFromApi) {
        friendsGroup.contacts.add(Contact(
          id: friend.userId,
          name: friend.username,
          avatarUrl: _apiService.getFullAvatarUrl(friend.avatarUrl),
          remark: friend.username, // 暂时用 username 作为 remark
          // 当API返回更多数据时，在这里填充
        ));
      }

      final newGroups = [
        ContactGroup(name: '新的朋友', contacts: []),
        ContactGroup(name: '群聊', contacts: []),
        if (friendsGroup.contacts.isNotEmpty) friendsGroup,
      ];

      if (mounted) {
        setState(() {
          _contactGroups = newGroups;
          _pendingRequestCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载好友列表失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFriends() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _apiService.getFriends(),
        _apiService.getPendingFriendRequestsCount(),
      ]);
      final friends = results[0] as List<UserSearchResult>;
      final count = results[1] as int;
      final friendsGroup = ContactGroup(name: "我的好友", contacts: []);
      for (var friend in friends) {
        friendsGroup.contacts.add(Contact(
          id: friend.userId,
          name: friend.username,
          avatarUrl: _apiService.getFullAvatarUrl(friend.avatarUrl),
          remark: friend.username,
        ));
      }

      // 创建最终的分组列表
      final newGroups = [
        ContactGroup(name: '新的朋友', contacts: []), // 为好友通知预留
        ContactGroup(name: '仅聊天', contacts: []),
        if (friendsGroup.contacts.isNotEmpty) friendsGroup,
      ];

      if (mounted) {
        setState(() {
          _contactGroups = newGroups;
          _pendingRequestCount = count;
        });
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载好友列表失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildContactsList(),
        // 当有联系人被选中时，显示适配后的详情面板
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
                const Expanded(
                  child: CustomSearchField(
                    hintText: '搜索',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onAddFriend, // 点击时调用父组件传来的方法
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A5855),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        const Icon(Icons.add, size: 20, color: Colors.white54),
                  ),
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
          _buildNotificationTile('好友通知',
              count: _pendingRequestCount,
              onTap: widget.onNavigateToFriendRequests // <-- 传递回调
              ),
          _buildNotificationTile('群通知', onTap: () {}),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Divider(color: Colors.white10, height: 1),
          ),

          _buildToggle(),

          // Contact Groups List
          Expanded(
            child: ListView.builder(
              itemCount: _contactGroups.length,
              itemBuilder: (context, index) {
                final group = _contactGroups[index];
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
    bool isSelected = _selectedContact?.id == contact.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContact = contact;
        });
      },
      child: Container(
        color: isSelected ? const Color(0xFF5A5855) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            CustomCircleAvatar(
              avatarUrl: contact.avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.remark,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  // 暂时移除 statusText，因为我们没有这个数据
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String title,
      {int count = 0, VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min, // 让 Row 的宽度自适应内容
        children: [
          // 只有当 count 大于 0 时才显示徽章
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),

          const SizedBox(width: 8), // 徽章和箭头的间距

          const Icon(
            Icons.chevron_right,
            color: Colors.white54,
            size: 20,
          ),
        ],
      ),
      dense: true,
      onTap: onTap,
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
