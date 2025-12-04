// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatHash() => r'04fa73378e4375084efe7386d1f883b9bb0df831';

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
    extends BuildlessAutoDisposeStreamNotifier<List<ChatMessage>> {
  late final String conversationId;
  late final String recipientId;

  Stream<List<ChatMessage>> build(
    String conversationId,
    String recipientId,
  );
}

/// 聊天会话状态管理 Provider
/// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
/// 【参数说明】
/// - conversationId: 当前会话的唯一标识
/// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
/// 【核心特性】
/// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
/// 2. 自动同步历史消息（进入会话时触发）
/// 3. 实时监听 MQTT 消息（仅处理当前会话）
/// 4. 支持文本/图片消息发送（含状态管理）
///
/// Copied from [Chat].
@ProviderFor(Chat)
const chatProvider = ChatFamily();

/// 聊天会话状态管理 Provider
/// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
/// 【参数说明】
/// - conversationId: 当前会话的唯一标识
/// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
/// 【核心特性】
/// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
/// 2. 自动同步历史消息（进入会话时触发）
/// 3. 实时监听 MQTT 消息（仅处理当前会话）
/// 4. 支持文本/图片消息发送（含状态管理）
///
/// Copied from [Chat].
class ChatFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// 聊天会话状态管理 Provider
  /// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
  /// 【参数说明】
  /// - conversationId: 当前会话的唯一标识
  /// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
  /// 【核心特性】
  /// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
  /// 2. 自动同步历史消息（进入会话时触发）
  /// 3. 实时监听 MQTT 消息（仅处理当前会话）
  /// 4. 支持文本/图片消息发送（含状态管理）
  ///
  /// Copied from [Chat].
  const ChatFamily();

  /// 聊天会话状态管理 Provider
  /// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
  /// 【参数说明】
  /// - conversationId: 当前会话的唯一标识
  /// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
  /// 【核心特性】
  /// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
  /// 2. 自动同步历史消息（进入会话时触发）
  /// 3. 实时监听 MQTT 消息（仅处理当前会话）
  /// 4. 支持文本/图片消息发送（含状态管理）
  ///
  /// Copied from [Chat].
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

/// 聊天会话状态管理 Provider
/// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
/// 【参数说明】
/// - conversationId: 当前会话的唯一标识
/// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
/// 【核心特性】
/// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
/// 2. 自动同步历史消息（进入会话时触发）
/// 3. 实时监听 MQTT 消息（仅处理当前会话）
/// 4. 支持文本/图片消息发送（含状态管理）
///
/// Copied from [Chat].
class ChatProvider
    extends AutoDisposeStreamNotifierProviderImpl<Chat, List<ChatMessage>> {
  /// 聊天会话状态管理 Provider
  /// 负责单个聊天会话的消息流管理、消息发送、MQTT 监听等核心功能
  /// 【参数说明】
  /// - conversationId: 当前会话的唯一标识
  /// - recipientId: 接收方用户 ID（用于发送消息时定位目标）
  /// 【核心特性】
  /// 1. 基于仓库模式封装数据逻辑（解耦 UI 与数据层）
  /// 2. 自动同步历史消息（进入会话时触发）
  /// 3. 实时监听 MQTT 消息（仅处理当前会话）
  /// 4. 支持文本/图片消息发送（含状态管理）
  ///
  /// Copied from [Chat].
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
  Stream<List<ChatMessage>> runNotifierBuild(
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
  AutoDisposeStreamNotifierProviderElement<Chat, List<ChatMessage>>
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

mixin ChatRef on AutoDisposeStreamNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;

  /// The parameter `recipientId` of this provider.
  String get recipientId;
}

class _ChatProviderElement
    extends AutoDisposeStreamNotifierProviderElement<Chat, List<ChatMessage>>
    with ChatRef {
  _ChatProviderElement(super.provider);

  @override
  String get conversationId => (origin as ChatProvider).conversationId;
  @override
  String get recipientId => (origin as ChatProvider).recipientId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
