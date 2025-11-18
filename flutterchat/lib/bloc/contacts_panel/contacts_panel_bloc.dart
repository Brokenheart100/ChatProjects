// 文件: lib/blocs/contacts_panel/contacts_panel_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/api_service.dart';

part 'contacts_panel_event.dart';
part 'contacts_panel_state.dart';

class ContactsPanelBloc extends Bloc<ContactsPanelEvent, ContactsPanelState> {
  final ApiService _apiService;

  ContactsPanelBloc({required ApiService apiService})
      : _apiService = apiService,
        super(const ContactsPanelState()) {
    // 注册事件处理器
    on<LoadContactsData>(_onLoadContactsData);
    on<ToggleContactGroup>(_onToggleContactGroup);
    on<SelectContact>(_onSelectContact);
    on<ClearSelectedContact>(_onClearSelectedContact);
  }

  /// 处理加载数据的事件
  Future<void> _onLoadContactsData(
    LoadContactsData event,
    Emitter<ContactsPanelState> emit,
  ) async {
    emit(state.copyWith(isLoading: true)); // 发出一个“正在加载”的状态
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
          remark: friend.username,
        ));
      }

      final newGroups = [
        ContactGroup(name: '新的朋友', contacts: []),
        ContactGroup(name: '群聊', contacts: []),
        if (friendsGroup.contacts.isNotEmpty) friendsGroup,
      ];

      // 发出一个包含所有新数据的“加载完成”状态
      emit(state.copyWith(
        isLoading: false,
        contactGroups: newGroups,
        pendingRequestCount: count,
      ));
    } catch (e) {
      // 发出一个“加载失败”的状态
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// 处理展开/折叠分组的事件
  void _onToggleContactGroup(
    ToggleContactGroup event,
    Emitter<ContactsPanelState> emit,
  ) {
    final newExpandedGroups = Set<String>.from(state.expandedGroups);
    if (newExpandedGroups.contains(event.groupName)) {
      newExpandedGroups.remove(event.groupName);
    } else {
      newExpandedGroups.add(event.groupName);
    }
    emit(state.copyWith(expandedGroups: newExpandedGroups));
  }

  /// 处理选中联系人的事件
  void _onSelectContact(
    SelectContact event,
    Emitter<ContactsPanelState> emit,
  ) {
    emit(state.copyWith(selectedContact: event.contact));
  }

  /// 处理清除选中联系人的事件
  void _onClearSelectedContact(
    ClearSelectedContact event,
    Emitter<ContactsPanelState> emit,
  ) {
    emit(state.copyWith(clearSelectedContact: true));
  }
}
