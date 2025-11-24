// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatHash() => r'22874cd7032ee5a648ef20867833ea864ae6469c';

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

abstract class _$Chat
    extends BuildlessAutoDisposeAsyncNotifier<List<ChatMessage>> {
  late final String conversationId;
  late final String recipientId;

  FutureOr<List<ChatMessage>> build(
    String conversationId,
    String recipientId,
  );
}

/// See also [Chat].
@ProviderFor(Chat)
const chatProvider = ChatFamily();

/// See also [Chat].
class ChatFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [Chat].
  const ChatFamily();

  /// See also [Chat].
  ChatProvider call(
    String conversationId,
    String recipientId,
  ) {
    return ChatProvider(
      conversationId,
      recipientId,
    );
  }

  @override
  ChatProvider getProviderOverride(
    covariant ChatProvider provider,
  ) {
    return call(
      provider.conversationId,
      provider.recipientId,
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
  String? get name => r'chatProvider';
}

/// See also [Chat].
class ChatProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Chat, List<ChatMessage>> {
  /// See also [Chat].
  ChatProvider(
    String conversationId,
    String recipientId,
  ) : this._internal(
          () => Chat()
            ..conversationId = conversationId
            ..recipientId = recipientId,
          from: chatProvider,
          name: r'chatProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$chatHash,
          dependencies: ChatFamily._dependencies,
          allTransitiveDependencies: ChatFamily._allTransitiveDependencies,
          conversationId: conversationId,
          recipientId: recipientId,
        );

  ChatProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
    required this.recipientId,
  }) : super.internal();

  final String conversationId;
  final String recipientId;

  @override
  FutureOr<List<ChatMessage>> runNotifierBuild(
    covariant Chat notifier,
  ) {
    return notifier.build(
      conversationId,
      recipientId,
    );
  }

  @override
  Override overrideWith(Chat Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatProvider._internal(
        () => create()
          ..conversationId = conversationId
          ..recipientId = recipientId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
        recipientId: recipientId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Chat, List<ChatMessage>>
      createElement() {
    return _ChatProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatProvider &&
        other.conversationId == conversationId &&
        other.recipientId == recipientId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);
    hash = _SystemHash.combine(hash, recipientId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChatRef on AutoDisposeAsyncNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;

  /// The parameter `recipientId` of this provider.
  String get recipientId;
}

class _ChatProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Chat, List<ChatMessage>>
    with ChatRef {
  _ChatProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatProvider).conversationId;
  @override
  String get recipientId => (origin as ChatProvider).recipientId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
