import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/providers/contact_provider.dart';
import 'package:flutterchat/services/logger_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/providers/services_provider.dart';

part 'online_status_provider.g.dart';

// 全局在线用户集合
@Riverpod(keepAlive: true)
class OnlineUsers extends _$OnlineUsers {
  @override
  Set<String> build() {
    // 初始化：监听 MQTT 状态变更事件
    // 假设后端推送到 'system/status' 或类似 Topic
    final mqtt = ref.watch(mqttServiceProvider);

    // 监听状态流 (我们需要在 MqttService 里加这个流，见下一步)
    final sub = mqtt.onUserStatusChanged.listen((event) {
      logger.i(
          "📡 [OnlineUsers] 收到MQTT状态变更: ${event.userId} -> ${event.isOnline}");
      _updateStatus(event.userId, event.isOnline);
    });

    ref.onDispose(() => sub.cancel());

    // Future.microtask(() => _fetchInitialStatus());
    ref.listen(contactListProvider, (previous, next) {
      next.whenData((groups) {
        if (groups.isNotEmpty) {
          logger.i("👥 [OnlineUsers] 联系人列表已更新，准备刷新在线状态...");
          _fetchStatusForGroups(groups);
        }
      });
    });
    return {}; // 初始默认全离线，或者等待 API 拉取初始状态
  }

  // 提取出来的批量查询方法
  Future<void> _fetchStatusForGroups(List<ContactGroup> groups) async {
    try {
      // 3. 逻辑增强：获取所有分组的所有联系人 ID (不仅仅是"我的好友")
      // 很多时候如果不显示，是因为好友被分到了别的组，或者组名不一样
      final allContactIds = groups
          .expand((g) => g.contacts) // 展开所有分组
          .where((c) => !c.isGroup) // 排除群聊
          .map((c) => c.id)
          .toSet() // 去重
          .toList();

      if (allContactIds.isEmpty) return;

      final api = ref.read(apiServiceProvider);
      final statusMap = await api.getOnlineStatusBatch(allContactIds);

      final onlineIds = statusMap.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toSet();

      // 这里使用 union 可能会导致离线的人删不掉，建议直接覆盖，或者根据业务逻辑合并
      // 这里演示直接覆盖在线名单（因为是全量查询）
      state = onlineIds;
      logger.i("✅ [OnlineUsers] 批量同步完成，当前在线人数: ${onlineIds.length}");
    } catch (e) {
      logger.e("❌ 拉取在线状态失败", error: e);
    }
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final contacts = await ref.read(contactListProvider.future);

      // ✅ 核心修复：明确指定类型，防止推断为 List<dynamic>
      final friendIds = contacts
          .expand((g) =>
              g.name == '我的好友' ? g.contacts : const <Contact>[]) // 1. 这里的空列表加类型
          .map((c) => c.id)
          .toList(); // 2. 或者使用 .toList().cast<String>()

      if (friendIds.isEmpty) return;

      final api = ref.read(apiServiceProvider);

      // 现在 friendIds 是 List<String> 了，不会报错
      final statusMap = await api.getOnlineStatusBatch(friendIds);

      final onlineIds = statusMap.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toSet();

      state = onlineIds;
      logger.i("✅ [OnlineUsers] 初始状态同步完成，在线好友数: ${onlineIds.length}");
    } catch (e) {
      logger.e("拉取在线状态失败", error: e);
    }
  }

  void _updateStatus(String userId, bool isOnline) {
    final current = Set<String>.from(state);
    if (isOnline) {
      current.add(userId);
    } else {
      current.remove(userId);
    }
    state = current;
  }

  // 提供给外部调用的方法：批量更新 (例如刚登录时拉取好友在线状态)
  void setOnlineBatch(List<String> userIds) {
    final current = Set<String>.from(state);
    current.addAll(userIds);
    state = current;
  }
}
