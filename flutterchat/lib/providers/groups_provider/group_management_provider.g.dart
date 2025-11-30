// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_management_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupManagementHash() => r'11789e9037bd5c354b10328973a04074306d9fa1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$GroupManagement
    extends BuildlessAutoDisposeAsyncNotifier<GroupDetail> {
  late final String groupId;

  FutureOr<GroupDetail> build(
    String groupId,
  );
}

/// See also [GroupManagement].
@ProviderFor(GroupManagement)
const groupManagementProvider = GroupManagementFamily();

/// See also [GroupManagement].
class GroupManagementFamily extends Family<AsyncValue<GroupDetail>> {
  /// See also [GroupManagement].
  const GroupManagementFamily();

  /// See also [GroupManagement].
  GroupManagementProvider call(
    String groupId,
  ) {
    return GroupManagementProvider(
      groupId,
    );
  }

  @override
  GroupManagementProvider getProviderOverride(
    covariant GroupManagementProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupManagementProvider';
}

/// See also [GroupManagement].
class GroupManagementProvider
    extends AutoDisposeAsyncNotifierProviderImpl<GroupManagement, GroupDetail> {
  /// See also [GroupManagement].
  GroupManagementProvider(
    String groupId,
  ) : this._internal(
          () => GroupManagement()..groupId = groupId,
          from: groupManagementProvider,
          name: r'groupManagementProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupManagementHash,
          dependencies: GroupManagementFamily._dependencies,
          allTransitiveDependencies:
              GroupManagementFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupManagementProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  FutureOr<GroupDetail> runNotifierBuild(
    covariant GroupManagement notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupManagement Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupManagementProvider._internal(
        () => create()..groupId = groupId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<GroupManagement, GroupDetail>
      createElement() {
    return _GroupManagementProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupManagementProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupManagementRef on AutoDisposeAsyncNotifierProviderRef<GroupDetail> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupManagementProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupManagement,
        GroupDetail> with GroupManagementRef {
  _GroupManagementProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupManagementProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
