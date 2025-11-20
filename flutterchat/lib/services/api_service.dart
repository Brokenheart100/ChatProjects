import 'package:dio/dio.dart'; // 网络请求库，用于发送HTTP请求
import 'package:flutterchat/models/auth_response.dart'; // 认证响应数据模型
import 'package:flutterchat/models/chat_message.dart';
import 'package:flutterchat/models/friend_request.dart';
import 'package:flutterchat/models/user_search_result.dart';
import 'package:flutterchat/services/logger_service.dart'; // 日志服务，用于记录系统日志
import 'package:image_picker/image_picker.dart'; // 图片选择库，用于获取本地图片文件
import 'package:shared_preferences/shared_preferences.dart'; // 本地存储库，用于保存认证token

/// 文件上传信息模型
/// 用于存储从后端获取的预签名上传URL和文件唯一标识
class UploadInfo {
  final String uploadUrl; // 预签名的文件上传URL（用于直接上传到对象存储）
  final String objectKey; // 文件在对象存储中的唯一标识（用于后续访问文件）

  // 构造函数：必须传入上传URL和对象标识
  UploadInfo({required this.uploadUrl, required this.objectKey});

  // 从JSON数据解析为UploadInfo实例
  factory UploadInfo.fromJson(Map<String, dynamic> json) {
    return UploadInfo(
      uploadUrl: json['uploadUrl'], // 从JSON中提取上传URL
      objectKey: json['objectKey'], // 从JSON中提取对象标识
    );
  }
}

/// API服务类
/// 封装与后端API的所有交互，包括认证（登录/注册）、文件上传等功能
class ApiService {
  final Dio _dio; // 用于普通API请求的Dio实例（带基础URL和拦截器）
  final Dio _uploadDio; // 用于文件上传的Dio实例（无固定基础URL，使用预签名URL）
  static const String _tokenKey = 'auth_token'; // 本地存储中保存token的键名
  static const String _baseUrl = 'https://localhost:7265'; // 后端API基础地址

  /// 构造函数：初始化Dio实例并配置拦截器
  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl, // 配置基础URL
          connectTimeout: const Duration(seconds: 5), // 连接超时时间：5秒
          receiveTimeout: const Duration(seconds: 30), // 接收超时时间：30秒
          headers: {'Content-Type': 'application/json'}, // 默认请求头：JSON格式
        )),
        _uploadDio = Dio() {
    // 为普通请求Dio添加拦截器：自动添加认证token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 登录和注册接口不需要携带token（未认证状态）
        if (options.path != '/gateway/auth/login' &&
            options.path != '/gateway/auth/register') {
          logger.d('为请求添加认证token...');
          final token = await getToken(); // 从本地获取token
          if (token != null) {
            // 添加Bearer Token认证头
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options); // 继续处理请求
      },
      onError: (DioException e, handler) async {
        // (可选，但推荐) 在这里处理 401 错误，例如令牌过期
        if (e.response?.statusCode == 401) {
          // 令牌无效或过期，可以在这里尝试刷新令牌，或者直接清除本地凭据并导航到登录页
          await logout();
        }
        return handler.next(e);
      },
    ));
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    // --- 1. 添加日志：记录方法被调用和参数 ---
    logger.i('开始搜索用户，查询关键词: "$query"');

    try {
      final response = await _dio.get(
        '/gateway/search/users',
        queryParameters: {'query': query},
      );

      final List<dynamic> jsonList = response.data;
      final results =
          jsonList.map((json) => UserSearchResult.fromJson(json)).toList();

      // --- 2. 添加日志：记录成功的结果 ---
      logger.i('成功搜索到 ${results.length} 个用户。');

      return results;
    } on DioException catch (e) {
      // --- 3. 添加日志：记录详细的错误信息 ---
      logger.e(
        '搜索用户失败！查询: "$query"',
        error: e, // 将 DioException 对象作为 error 参数传递
        stackTrace: e.stackTrace, // 传递堆栈信息
      );
      // ------------------------------------
      throw _handleError(e, "searchUsers");
    } catch (e, stackTrace) {
      // 捕获其他可能的非 Dio 异常
      logger.e(
        '解析搜索结果时发生未知错误！查询: "$query"',
        error: e,
        stackTrace: stackTrace,
      );
      throw '无法解析搜索结果: $e';
    }
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String recipientId) async {
    // --- 1. 添加日志：记录方法被调用和参数 ---
    logger.i('正在发送好友请求给用户 ID: $recipientId');

    try {
      await _dio.post(
        // 假设您的网关路由是 /gateway/friends/requests
        // 根据您后端的 FriendsController.cs 调整
        '/gateway/friends/requests',
        data: {'recipientId': recipientId},
      );

      // --- 2. 添加日志：记录成功的结果 ---
      logger.i('成功发送好友请求给用户 ID: $recipientId');
    } on DioException catch (e) {
      // --- 3. 添加日志：记录详细的错误信息 ---
      logger.e(
        '发送好友请求失败！接收方 ID: $recipientId',
        error: e,
        stackTrace: e.stackTrace,
      );
      // ------------------------------------
      throw _handleError(e, "sendFriendRequest");
    }
  }

  /// 上传文件并获取对象标识
  /// 完整流程：获取预签名URL -> 上传文件到对象存储 -> 返回对象标识
  /// [file]：待上传的本地文件（通过image_picker获取）
  /// 返回值：文件在对象存储中的唯一标识（objectKey）
  Future<String> uploadFileAndGetObjectKey(XFile file) async {
    logger.i('开始上传文件流程: ${file.name}');

    // 1. 从后端获取上传许可（预签名URL和对象标识）
    final uploadInfo = await _getUploadUrl(file.name);

    // 2. 使用预签名URL直接将文件上传到MinIO（对象存储服务）
    await _uploadFileToMinio(uploadInfo.uploadUrl, file);

    // 3. 返回文件唯一标识（用于后续关联到用户/消息等）
    logger.i('文件上传成功，ObjectKey: ${uploadInfo.objectKey}');
    return uploadInfo.objectKey;
  }

  /// 私有方法：将文件上传到MinIO对象存储
  /// [uploadUrl]：预签名的上传URL（由后端生成）
  /// [file]：待上传的本地文件
  Future<void> _uploadFileToMinio(String uploadUrl, XFile file) async {
    logger.i('正在将文件上传到MinIO...');
    try {
      // 读取文件字节数据
      final fileBytes = await file.readAsBytes();
      // 使用PUT请求上传文件（预签名URL通常要求PUT方法）
      final response = await _uploadDio.put(
        uploadUrl,
        // 以流的形式上传（适合大文件，减少内存占用）
        data: Stream.fromIterable(fileBytes.map((e) => [e])),
        options: Options(
          headers: {
            // 必须指定内容长度，否则对象存储可能拒绝请求
            Headers.contentLengthHeader: fileBytes.length,
            // 指定内容类型为图片（确保MinIO能正确识别和预览）
            Headers.contentTypeHeader: 'image/jpeg',
          },
        ),
      );

      // 检查上传状态（200表示成功）
      if (response.statusCode != 200) {
        throw '文件上传到MinIO失败, 状态码: ${response.statusCode}';
      }
      logger.i('文件成功上传到MinIO。');
    } on DioException catch (e) {
      logger.e('上传文件到MinIO失败', error: e);
      throw '文件上传失败: ${e.message}';
    }
  }

  /// 私有方法：获取文件上传的预签名URL（内部使用）
  /// [fileName]：待上传的文件名（用于后端生成唯一标识）
  /// 返回值：包含上传URL和对象标识的UploadInfo实例
  Future<UploadInfo> _getUploadUrl(String fileName) async {
    logger.i('正在为 "$fileName" 请求上传URL...');
    try {
      // 调用后端接口生成上传URL
      final response = await _dio.get(
        '/gateway/files/generate-upload-url', // 后端生成预签名URL的接口
        queryParameters: {'fileName': fileName}, // 传入文件名参数
      );
      if (response.statusCode == 200) {
        logger.i('成功获取上传URL。');
        return UploadInfo.fromJson(response.data); // 解析响应数据为UploadInfo
      } else {
        throw '获取上传URL失败';
      }
    } on DioException catch (e) {
      // 调用错误处理方法，传入上下文标识
      throw _handleError(e, "getUploadUrl");
    }
  }

  /// 公开方法：获取文件上传的预签名URL（外部调用）
  /// [fileName]：待上传的文件名
  /// 返回值：包含上传URL和对象标识的UploadInfo实例
  Future<UploadInfo> getUploadUrl(String fileName) async {
    logger.i('请求上传URL: $fileName');
    try {
      final response = await _dio.get(
        '/gateway/files/generate-upload-url',
        queryParameters: {'fileName': fileName},
      );
      if (response.statusCode == 200) {
        logger.i('成功接收上传URL。');
        return UploadInfo.fromJson(response.data);
      } else {
        throw '获取上传URL失败';
      }
    } on DioException catch (e) {
      throw _handleError(e, "getUploadUrl");
    }
  }

  /// 用户注册接口
  /// [username]：用户名
  /// [email]：邮箱
  /// [password]：密码
  /// [avatarUrl]：头像URL（可选，可在注册时上传头像）
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? avatarUrl, // 新增头像参数
  }) async {
    logger.i('尝试注册用户: $username，头像: $avatarUrl');
    try {
      // 发送POST请求到注册接口
      final response = await _dio.post(
        '/gateway/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'avatarUrl': avatarUrl, // 携带头像URL到后端
        },
      );
      logger.i('用户 $username 注册成功，状态码: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleError(e, "register"); // 处理注册错误
    }
  }

  /// 用户登录接口
  /// [username]：用户名
  /// [password]：密码
  /// 返回值：包含用户信息和token的AuthResponse实例
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    logger.i('尝试登录用户: $username');
    try {
      // 发送POST请求到登录接口
      final response = await _dio.post(
        '/gateway/auth/login',
        data: {'username': username, 'password': password},
      );

      // 登录成功：解析响应并保存token
      if (response.statusCode == 200 && response.data != null) {
        logger.i('用户 $username 登录成功');
        final authResponse = AuthResponse.fromJson(response.data); // 解析用户信息
        await saveToken(authResponse.token); // 保存token到本地
        return authResponse; // 返回完整用户信息
      } else {
        throw '登录失败，未获取到token。';
      }
    } on DioException catch (e) {
      throw _handleError(e); // 处理登录错误
    }
  }

  /// 生成完整的头像URL
  /// [objectKey]：头像在对象存储中的唯一标识
  /// 返回值：可直接访问的头像完整URL
  String getFullAvatarUrl(String? objectKey) {
    // 若对象标识为空，返回空字符串（可替换为默认头像URL）
    if (objectKey == null || objectKey.isEmpty) {
      return '';
    }

    const String bucketName = 'avatars'; // MinIO中存储头像的桶名
    const String minioBaseUrl = 'http://localhost:9000'; // MinIO服务地址

    // 拼接完整URL：MinIO地址/桶名/对象标识
    return '$minioBaseUrl/$bucketName/$objectKey';
  }

  /// 统一错误处理方法
  /// [e]：Dio异常对象
  /// [context]：错误发生的上下文（可选，用于定位错误位置）
  /// 返回值：用户友好的错误提示信息
  String _handleError(DioException e, [String? context]) {
    final contextMessage = context != null ? '（发生在 $context）' : '';
    logger.e(
      'ApiService 错误$contextMessage',
      error: e,
      stackTrace: e.stackTrace,
    );

    if (e.response != null) {
      // 有响应的错误（后端返回错误）
      logger.w('错误响应数据: ${e.response?.data}');
      // 若响应数据是字符串且非空，直接返回
      if (e.response?.data is String && e.response!.data.isNotEmpty) {
        return e.response!.data;
      }
      // 处理409冲突（用户名/邮箱已存在）
      if (e.response?.statusCode == 409) {
        return '用户名或邮箱已存在。';
      }
      // 其他服务器错误
      return '服务器错误, 状态码: ${e.response?.statusCode}';
    } else {
      // 无响应的错误（网络问题或超时）
      logger.w('网络或其他错误: ${e.message}');
      // 超时错误
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return '服务器响应超时，请稍后重试。';
      }
      // 其他连接错误
      return '无法连接到服务器, 请检查网络或服务地址。';
    }
  }

  /// 用户登出
  /// 移除本地存储的认证token
  Future<void> logout() async {
    logger.i('正在执行注销操作，清除本地 Token...');
    final prefs = await SharedPreferences.getInstance();

    // 移除保存的 Token
    await prefs.remove(_tokenKey);

    logger.i('本地 Token 已清除。');

    // (可选，但推荐) 同时清除 AccountService 中保存的账户信息
    // 这需要您在 AccountService 中也添加一个 clearAllAccounts 方法
    // final accountService = AccountService();
    // await accountService.clearAllAccounts();
  }

  Future<AuthResponse> getSession() async {
    logger.i('正在尝试通过已保存的 Token 恢复会话...');
    try {
      // Dio 拦截器会自动附加 Token
      final response = await _dio.get('/gateway/auth/session');

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        // 后端返回了新的 Token，我们用新 Token 覆盖旧的
        await saveToken(authResponse.token);
        logger.i('会话恢复成功！用户: ${authResponse.username}');
        return authResponse;
      } else {
        throw '会话恢复失败';
      }
    } on DioException catch (e) {
      // 如果 getSession 失败 (例如 Token 过期导致 401)，就清除本地 Token
      await logout();
      throw _handleError(e, "getSession");
    }
  }

  /// 保存认证token到本地存储
  /// [token]：待保存的JWT token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 从本地存储获取认证token
  /// 返回值：存储的token（若不存在则返回null）
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<List<UserSearchResult>> getFriends() async {
    logger.i('正在获取好友列表...');
    try {
      // API 调用需要登录，拦截器会自动附加 Token
      final response =
          await _dio.get('/gateway/friends'); // 假设网关路由是 /gateway/friends

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> jsonList = response.data;
        final friends =
            jsonList.map((json) => UserSearchResult.fromJson(json)).toList();
        logger.i('成功获取到 ${friends.length} 个好友。');
        return friends;
      } else {
        throw '获取好友列表失败';
      }
    } on DioException catch (e) {
      logger.e('获取好友列表失败！', error: e, stackTrace: e.stackTrace);
      throw _handleError(e, "getFriends");
    }
  }

  // --- 核心新增 ---
  Future<List<FriendRequest>> getPendingFriendRequests() async {
    final response = await _dio.get('/gateway/friends/requests/pending');
    final List<dynamic> jsonList = response.data;
    return jsonList.map((json) => FriendRequest.fromJson(json)).toList();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/accept');
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _dio.post('/gateway/friends/requests/$requestId/reject');
  }

  Future<int> getPendingFriendRequestsCount() async {
    try {
      final response =
          await _dio.get('/gateway/friends/requests/pending/count');
      if (response.statusCode == 200 && response.data != null) {
        // 从返回的 JSON 对象 { "count": 3 } 中解析出 count 的值
        final count = response.data['count'] as int;
        logger.i('获取到 $count 个待处理的好友请求。');
        return count;
      }
      return 0;
    } on DioException {
      // 发生错误时返回 0，避免 UI 崩溃
      return 0;
    }
  }

  Future<void> sendMessage(String conversationId, String content,
      {int contentType = 0, String? recipientId}) async {
    await _dio.post(
      '/gateway/messages', // 网关会把 /messages 路由到 ChatHistoryService
      data: {
        'conversationId': conversationId,
        'content': content,
        'contentType': 0, // 0 for Text
        'recipientId': recipientId,
      },
    );
  }

  // 确保方法签名包含 currentUserId
  Future<List<ChatMessage>> getMessageHistory(String conversationId,
      {required String currentUserId}) async {
    try {
      final response = await _dio.get(
        '/gateway/conversations/$conversationId/messages',
        queryParameters: {'limit': 20}, // 可以根据需要添加分页参数
      );

      final List<dynamic> data = response.data;

      return data.map((json) {
        // 获取消息发送者ID
        final senderId = json['senderId'].toString(); // 确保转为字符串比较

        return ChatMessage(
          // --- 核心逻辑：判断是否是自己发的消息 ---
          isMe: senderId == currentUserId,
          // -----------------------------------
          sender: json['senderId'], // 或者从其他地方获取昵称
          text: json['content'],
          contentType: json['contentType'] ?? 0,
          avatar: '', // 这里可以使用默认头像，或者根据 senderId 查找缓存的头像
        );
      }).toList();
    } on DioException {
      rethrow;
    }
  }
}
