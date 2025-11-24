// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiClientHash() => r'cdc65f44d0ec7d7c3a88a5d035707e0245b00546';

/// See also [apiClient].
@ProviderFor(apiClient)
final apiClientProvider = Provider<ApiClient>.internal(
  apiClient,
  name: r'apiClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiClientRef = ProviderRef<ApiClient>;
String _$apiServiceHash() => r'5b8beddb448316bdae5e3963ff77601653715729';

/// See also [apiService].
@ProviderFor(apiService)
final apiServiceProvider = Provider<ApiService>.internal(
  apiService,
  name: r'apiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiServiceRef = ProviderRef<ApiService>;
String _$accountServiceHash() => r'fb77e2ab09b9dfd51d737cdb90145916f73b43aa';

/// See also [accountService].
@ProviderFor(accountService)
final accountServiceProvider = Provider<AccountService>.internal(
  accountService,
  name: r'accountServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AccountServiceRef = ProviderRef<AccountService>;
String _$mqttServiceHash() => r'cfd61be6c66063d10770df38f4fef651fe6074e0';

/// See also [mqttService].
@ProviderFor(mqttService)
final mqttServiceProvider = Provider<MqttService>.internal(
  mqttService,
  name: r'mqttServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mqttServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MqttServiceRef = ProviderRef<MqttService>;
String _$mqttMessageStreamHash() => r'bcd5070208884176e9b888739a689156d3a99a31';

/// See also [mqttMessageStream].
@ProviderFor(mqttMessageStream)
final mqttMessageStreamProvider =
    AutoDisposeStreamProvider<ChatMessageEvent>.internal(
  mqttMessageStream,
  name: r'mqttMessageStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mqttMessageStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MqttMessageStreamRef = AutoDisposeStreamProviderRef<ChatMessageEvent>;
String _$currentUserHash() => r'72a475de9a71f7528268885da8d8e7d8ec41f407';

/// See also [CurrentUser].
@ProviderFor(CurrentUser)
final currentUserProvider =
    NotifierProvider<CurrentUser, AuthResponse?>.internal(
  CurrentUser.new,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUser = Notifier<AuthResponse?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
