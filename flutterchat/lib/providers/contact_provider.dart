import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/providers/services_provider.dart';

part 'contact_provider.g.dart';

@riverpod
class ExpandedGroups extends _$ExpandedGroups {
  @override
  Set<String> build() => {'我的好友'};
  void toggle(String name) {
    final current = Set<String>.from(state);
    if (current.contains(name)) {
      current.remove(name);
    } else {
      current.add(name);
    }
    state = current;
  }
}

@riverpod
Future<int> friendRequestCount(FriendRequestCountRef ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getPendingFriendRequestsCount();
}

@riverpod
Future<List<ContactGroup>> contactList(ContactListRef ref) async {
  final api = ref.watch(apiServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  // 1. 并行请求：好友列表 + 会话列表(用于提取群聊)
  // 注意：更严谨的做法是后端提供 getMyGroups 接口，这里我们复用 getConversations 简化
  final futureFriends = api.getFriends();
  final futureConversations =
      api.getConversations(currentUserId: currentUser.userId);

  final results = await Future.wait([futureFriends, futureConversations]);

  final friends = results[0] as List<UserSearchResult>;
  final conversations = results[1] as List<Conversation>;

  // 2. 提取群聊
  final groupChats = conversations
      .where((c) => c.isGroup)
      .map((c) => Contact(
            id: c.id,
            name: c.name,
            avatarUrl: c.avatar,
            remark: c.name, // 群聊备注暂同名
          ))
      .toList();

  // 3. 组装分组
  final myFriendsGroup = ContactGroup(
    name: "我的好友",
    contacts: friends
        .map((f) => Contact(
              id: f.userId,
              name: f.username,
              avatarUrl: api.getFullAvatarUrl(f.avatarUrl),
              remark: f.username,
            ))
        .toList(),
  );

  final myGroupsGroup = ContactGroup(
    name: "我的群聊", // <--- 新增分组
    contacts: groupChats,
  );

  return [
    ContactGroup(name: '新的朋友', contacts: []),
    // 4. 填充群聊数据
    myGroupsGroup,
    if (myFriendsGroup.contacts.isNotEmpty) myFriendsGroup,
  ];
}
