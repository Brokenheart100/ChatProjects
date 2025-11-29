// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupManagerHash() => r'47e93a1861d74d3d727643476b135e9ed4b79e46';

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

abstract class _$GroupManager
    extends BuildlessAutoDisposeAsyncNotifier<GroupMemberState> {
  late final String groupId;

  FutureOr<GroupMemberState> build(
    String groupId,
  );
}

/// See also [GroupManager].
@ProviderFor(GroupManager)
const groupManagerProvider = GroupManagerFamily();

/// See also [GroupManager].
class GroupManagerFamily extends Family<AsyncValue<GroupMemberState>> {
  /// See also [GroupManager].
  const GroupManagerFamily();

  /// See also [GroupManager].
  GroupManagerProvider call(
    String groupId,
  ) {
    return GroupManagerProvider(
      groupId,
    );
  }

  @override
  GroupManagerProvider getProviderOverride(
    covariant GroupManagerProvider provider,
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
  String? get name => r'groupManagerProvider';
}

/// See also [GroupManager].
class GroupManagerProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupManager, GroupMemberState> {
  /// See also [GroupManager].
  GroupManagerProvider(
    String groupId,
  ) : this._internal(
          () => GroupManager()..groupId = groupId,
          from: groupManagerProvider,
          name: r'groupManagerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupManagerHash,
          dependencies: GroupManagerFamily._dependencies,
          allTransitiveDependencies:
              GroupManagerFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupManagerProvider._internal(
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
  FutureOr<GroupMemberState> runNotifierBuild(
    covariant GroupManager notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupManager Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupManagerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<GroupManager, GroupMemberState>
      createElement() {
    return _GroupManagerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupManagerProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupManagerRef on AutoDisposeAsyncNotifierProviderRef<GroupMemberState> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupManagerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupManager,
        GroupMemberState> with GroupManagerRef {
  _GroupManagerProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupManagerProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
