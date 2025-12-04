// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mqttSystemStreamHash() => r'fbd7caae31f431d1233cec7a68019c59f79fba12';

/// MQTT 系统事件流 Provider
/// 提供 MQTT 服务的系统级事件监听能力（如连接状态变化、系统通知、异常事件等）
/// 依赖 [mqttServiceProvider]，当 MQTT 服务触发系统事件时，通过该流通知订阅者
///
/// Copied from [mqttSystemStream].
@ProviderFor(mqttSystemStream)
final mqttSystemStreamProvider =
    AutoDisposeStreamProvider<SystemEvent>.internal(
  mqttSystemStream,
  name: r'mqttSystemStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mqttSystemStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MqttSystemStreamRef = AutoDisposeStreamProviderRef<SystemEvent>;
String _$apiClientHash() => r'cdc65f44d0ec7d7c3a88a5d035707e0245b00546';

/// 1. 基础核心服务 Provider 组（单例模式）
/// 所有基础服务均设置 keepAlive: true，确保全局单例且不会被 Riverpod 自动销毁
/// 用于提供应用底层核心能力，无需手动管理生命周期
/// API 基础请求客户端 Provider
/// 提供最底层的网络请求能力（如 HTTP 客户端配置、请求拦截等）
/// 所有 API 相关操作的基础依赖，全局单例
///
/// Copied from [apiClient].
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

/// API 业务服务 Provider
/// 封装应用所有后端 API 接口调用（如登录、聊天、用户信息等业务接口）
/// 依赖 [apiClientProvider]，提供面向业务的 API 调用方法
///
/// Copied from [apiService].
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

/// 账户业务服务 Provider
/// 封装账户相关核心业务（如登录状态管理、令牌刷新、退出登录等）
/// 处理账户层面的逻辑封装，与 API 服务协作完成账户操作
///
/// Copied from [accountService].
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
String _$objectBoxHash() => r'94dbbc7a81c2d8e4e186a77fe5696d370acb0790';

/// ✅ 新增：ObjectBox 本地数据库服务 Provider
/// 提供本地数据库操作能力（数据存储、查询、更新、删除等）
/// 注意事项：
/// 1. 初始状态抛出未实现错误，因为 ObjectBox 需要在 main.dart 中初始化（依赖原生资源）
/// 2. 需在 main.dart 中通过 ProviderScope.override 覆盖该 Provider 的实现
/// 3. keepAlive: true 确保数据库连接全局复用，避免频繁创建销毁
///
/// Copied from [objectBox].
@ProviderFor(objectBox)
final objectBoxProvider = Provider<ObjectBoxService>.internal(
  objectBox,
  name: r'objectBoxProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$objectBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ObjectBoxRef = ProviderRef<ObjectBoxService>;
String _$mqttServiceHash() => r'74c30f4b0ada7e4648618f633810fa6d2cbd3033';

/// 3. MQTT 消息服务 Provider（依赖登录状态）
/// 提供 MQTT 协议的消息收发能力（聊天消息、实时通知等）
/// keepAlive: true 确保 MQTT 连接在登录后持续保持
///
/// Copied from [mqttService].
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

/// 4. MQTT 聊天消息流 Provider
/// 提供 MQTT 服务接收的聊天消息流，方便 UI 层监听实时消息
/// 无需设置 keepAlive：依赖的 [mqttServiceProvider] 已为单例，流会随服务生命周期变化
///
/// Copied from [mqttMessageStream].
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

/// 2. 全局当前登录用户状态 Provider
/// 采用 StateNotifier 模式，提供用户状态的修改和访问能力
/// keepAlive: true 确保用户状态在应用生命周期内全局共享（除非主动清除）
///
/// Copied from [CurrentUser].
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
