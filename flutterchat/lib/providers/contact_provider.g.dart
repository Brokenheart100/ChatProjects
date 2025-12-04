// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$friendRequestCountHash() =>
    r'3c7dc0254917662d41cf8056ad6680982211f4eb';

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
String _$contactListHash() => r'8c308387dec2c3a403ed70aa5d2f4040bd949cb7';

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
String _$expandedGroupsHash() => r'04ebce9c63d510bd802f3c6269dd3465591a2137';

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
