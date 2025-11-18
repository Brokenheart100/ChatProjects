// 文件: lib/blocs/contacts_panel/contacts_panel_state.dart

part of 'contacts_panel_bloc.dart'; // 这也是 BLoC 文件的一部分

@immutable
class ContactsPanelState extends Equatable {
  // UI 状态
  final bool isLoading;
  final String? errorMessage;

  // 数据状态
  final List<ContactGroup> contactGroups;
  final int pendingRequestCount;
  final Contact? selectedContact;
  final Set<String> expandedGroups;

  const ContactsPanelState({
    this.isLoading = true,
    this.errorMessage,
    this.contactGroups = const [],
    this.pendingRequestCount = 0,
    this.selectedContact,
    this.expandedGroups = const {'我的好友'},
  });

  // copyWith 方法使得状态更新非常方便和安全
  ContactsPanelState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ContactGroup>? contactGroups,
    int? pendingRequestCount,
    Contact? selectedContact,
    Set<String>? expandedGroups,
    bool clearSelectedContact = false, // 用于清除选中联系人的特殊标志
  }) {
    return ContactsPanelState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      contactGroups: contactGroups ?? this.contactGroups,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
      selectedContact: clearSelectedContact
          ? null
          : (selectedContact ?? this.selectedContact),
      expandedGroups: expandedGroups ?? this.expandedGroups,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        contactGroups,
        pendingRequestCount,
        selectedContact,
        expandedGroups,
      ];
}
