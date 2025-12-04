import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/repositories/contact_repository.dart'; // ✅ 引入 Repo

part 'contact_provider.g.dart';

// UI 展开/收起分组的状态 (保持不变，这是纯 UI 状态)
@riverpod
class ExpandedGroups extends _$ExpandedGroups {
  @override
  Set<String> build() => {'我的好友', '我的群聊'}; // 默认展开
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

// 红点计数 Provider (变得很薄)
@riverpod
Future<int> friendRequestCount(FriendRequestCountRef ref) async {
  // 1. 监听 Repo
  final repo = ref.watch(contactRepositoryProvider);
  // 2. 调用方法
  return repo.getPendingRequestCount();
}

// 通讯录列表 Provider (变得非常干净)
@riverpod
Future<List<ContactGroup>> contactList(ContactListRef ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  // 1. 监听 Repo
  final repo = ref.watch(contactRepositoryProvider);

  // 2. 只需要调用一个方法，所有复杂的聚合逻辑都在 Repo 里处理了
  return repo.fetchContactList(currentUser.userId);
}
