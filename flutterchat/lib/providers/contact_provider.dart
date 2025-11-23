import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (current.contains(name))
      current.remove(name);
    else
      current.add(name);
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
  final friends = await api.getFriends();

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

  return [
    ContactGroup(name: '新的朋友', contacts: []),
    ContactGroup(name: '群聊', contacts: []),
    if (myFriendsGroup.contacts.isNotEmpty) myFriendsGroup,
  ];
}
