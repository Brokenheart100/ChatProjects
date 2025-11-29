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
<<<<<<< HEAD
String _$conversationListHash() => r'dec6c485a36c3adce4c975a1eed4ee647e182644';
=======
String _$conversationListHash() => r'aeec0b9b6b9a703ac0c67d9093646054af9da642';
>>>>>>> 12a97aced4c74d164196155d43cbdfd3eb13aaf7

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
