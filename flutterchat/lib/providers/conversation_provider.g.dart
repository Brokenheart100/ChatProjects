// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedConversationIndexHash() =>
    r'71f01f2cb0268929b1f1d8ddc1dddc0870261ae7';

/// See also [SelectedConversationIndex].
@ProviderFor(SelectedConversationIndex)
final selectedConversationIndexProvider =
    AutoDisposeNotifierProvider<SelectedConversationIndex, int>.internal(
  SelectedConversationIndex.new,
  name: r'selectedConversationIndexProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedConversationIndexHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedConversationIndex = AutoDisposeNotifier<int>;
String _$conversationListHash() => r'dec6c485a36c3adce4c975a1eed4ee647e182644';

/// See also [ConversationList].
@ProviderFor(ConversationList)
final conversationListProvider =
    AsyncNotifierProvider<ConversationList, List<Conversation>>.internal(
  ConversationList.new,
  name: r'conversationListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversationList = AsyncNotifier<List<Conversation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
