// 文件: lib/blocs/contacts_panel/contacts_panel_event.dart

part of 'contacts_panel_bloc.dart';

@immutable
abstract class ContactsPanelEvent extends Equatable {
  const ContactsPanelEvent();

  @override
  List<Object?> get props => [];
}

/// 事件：加载好友列表和通知计数
class LoadContactsData extends ContactsPanelEvent {}

/// 事件：展开或折叠一个联系人分组
class ToggleContactGroup extends ContactsPanelEvent {
  final String groupName;

  const ToggleContactGroup(this.groupName);

  @override
  List<Object?> get props => [groupName];
}

/// 事件：选中一个联系人
class SelectContact extends ContactsPanelEvent {
  final Contact contact;

  const SelectContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

/// 事件：清除选中的联系人（例如，切换到其他面板时）
class ClearSelectedContact extends ContactsPanelEvent {}
