import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutterchat/models/contact.dart';
import 'package:flutterchat/models/contact_group.dart';
import 'package:flutterchat/models/conversation.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/providers/services_provider.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/services/logger_service.dart';

part 'contact_repository.g.dart';

// 定义 Repository Provider
// keepAlive: true 确保仓库单例，避免重复创建
@Riverpod(keepAlive: true)
ContactRepository contactRepository(ContactRepositoryRef ref) {
  return ContactRepository(api: ref.watch(apiServiceProvider));
}

class ContactRepository {
  final ApiService _api;

  ContactRepository({required ApiService api}) : _api = api;

  // ==========================================
  // 1. 核心读取：获取通讯录列表 (Read)
  // ==========================================

  /// 获取完整的通讯录数据结构 (好友 + 群组)
  /// 这是一个典型的"聚合"方法，并行请求多个接口，组装成 UI 需要的格式
  Future<List<ContactGroup>> fetchContactList(String currentUserId) async {
    try {
      logger.i("📥 [ContactRepo] 开始拉取通讯录数据...");

      // 1. 并行请求：提高加载速度
      // 同时发起"获取好友列表"和"获取会话列表"(用于提取群聊)
      // 注意：更严谨的后端设计应该提供独立的 /my-groups 接口，这里沿用你的逻辑从会话提取
      final results = await Future.wait([
        _api.getFriends(),
        _api.getConversations(currentUserId: currentUserId),
      ]);

      final friends = results[0] as List<UserSearchResult>;
      final conversations = results[1] as List<Conversation>;

      logger.d(
          "✅ [ContactRepo] API 返回: ${friends.length} 个好友, ${conversations.length} 个会话");

      // 2. 数据转换：DTO -> Domain Model
      // 将 API 返回的数据转换为 UI 统一使用的 Contact 模型

      // A. 提取群聊 (isGroup == true)
      final groupContacts = conversations
          .where((c) => c.isGroup)
          .map((c) => Contact(
                id: c.uuid,
                name: c.name,
                avatarUrl: c.avatar,
                remark: c.name, // 群聊暂时使用群名作为备注
                isGroup: true,
              ))
          .toList();

      // B. 转换好友
      final friendContacts = friends
          .map((f) => Contact(
                id: f.userId,
                name: f.username,
                avatarUrl: _api.getFullAvatarUrl(f.avatarUrl), // 确保头像路径完整
                remark: f.username, // 如果有备注名功能，这里应优先显示备注
                isGroup: false,
                // 扩展：这里可以加入 UserCache 逻辑，把好友信息顺手存入 ObjectBox
              ))
          .toList();

      // 3. 组装分组 (按固定顺序)
      final List<ContactGroup> resultGroups = [
        // 固定分组：新的朋友 (点击跳转到请求列表)
        ContactGroup(name: '新的朋友', contacts: []),

        // 分组：我的群聊
        ContactGroup(
          name: '我的群聊',
          contacts: groupContacts,
          // countDisplay: '${groupContacts.length}个',
        ),

        // 分组：我的好友 (如果为空则不显示，或者显示空占位)
        if (friendContacts.isNotEmpty)
          ContactGroup(
            name: '我的好友',
            contacts: friendContacts,
            // countDisplay: '${friendContacts.length}人',
          ),
      ];

      return resultGroups;
    } catch (e) {
      logger.e("❌ [ContactRepo] 拉取通讯录失败", error: e);
      rethrow; // 抛出异常，让 UI (AsyncValue) 处理错误状态
    }
  }

  // ==========================================
  // 2. 好友请求管理 (Request Management)
  // ==========================================

  /// 获取待处理的好友请求数量 (用于红点气泡)
  Future<int> getPendingRequestCount() async {
    try {
      return await _api.getPendingFriendRequestsCount();
    } catch (e) {
      // 获取红点失败不应阻断流程，静默返回 0
      logger.w("获取好友请求数量失败: $e");
      return 0;
    }
  }

  /// 获取好友请求列表
  Future<List<FriendRequest>> getPendingRequests() async {
    return await _api.getPendingFriendRequests();
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String userId) async {
    logger.i("📤 [ContactRepo] 发送好友请求 -> $userId");
    await _api.sendFriendRequest(userId);
  }

  /// 接受好友请求
  Future<void> acceptRequest(String requestId) async {
    logger.i("🤝 [ContactRepo] 接受好友请求: $requestId");
    await _api.acceptFriendRequest(requestId);
  }

  /// 拒绝好友请求
  Future<void> rejectRequest(String requestId) async {
    logger.i("👋 [ContactRepo] 拒绝好友请求: $requestId");
    await _api.rejectFriendRequest(requestId);
  }
}
