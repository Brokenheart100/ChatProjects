// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$friendRequestCountHash() =>
    r'3e7b5b6e5550341c3178305b6f21925d3f3404e3';

/// See also [friendRequestCount].
@ProviderFor(friendRequestCount)
final friendRequestCountProvider = AutoDisposeFutureProvider<int>.internal(
  friendRequestCount,
  name: r'friendRequestCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$friendRequestCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FriendRequestCountRef = AutoDisposeFutureProviderRef<int>;
String _$contactListHash() => r'46286228b60a0ed118b824f66440d93cbc348354';

/// See also [contactList].
@ProviderFor(contactList)
final contactListProvider =
    AutoDisposeFutureProvider<List<ContactGroup>>.internal(
  contactList,
  name: r'contactListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$contactListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ContactListRef = AutoDisposeFutureProviderRef<List<ContactGroup>>;
String _$expandedGroupsHash() => r'fe54a30cda1cf1ffc17e6e879822b5a231d9a95a';

/// See also [ExpandedGroups].
@ProviderFor(ExpandedGroups)
final expandedGroupsProvider =
    AutoDisposeNotifierProvider<ExpandedGroups, Set<String>>.internal(
  ExpandedGroups.new,
  name: r'expandedGroupsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expandedGroupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExpandedGroups = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
