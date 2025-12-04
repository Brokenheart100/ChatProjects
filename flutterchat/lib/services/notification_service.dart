import 'dart:io';
import 'package:dio/dio.dart'; // 1. 正常引入 Dio
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutterchat/services/logger_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初始化
  static Future<void> init() async {
    // Android 设置 (必须要有，否则 Android 上会崩)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Linux 设置
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Windows 设置
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'FlutterChat',
      appUserModelId: 'com.flutterchat.app',
      guid: '81a3405e-6015-4691-8b3f-1447d13d63c8',
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
      windows: initializationSettingsWindows,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _onNotificationTap(details.payload);
      },
    );
  }

  /// 点击回调
  static Future<void> _onNotificationTap(String? payload) async {
    logger.i("👆 点击了通知，Payload: $payload");
    await windowManager.show();
    await windowManager.focus();
  }

  /// ✅ 修复：使用 Dio 下载图片
  static Future<String?> _downloadAndSaveFile(
      String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);

      // 创建一个纯净的 Dio 实例（不带拦截器）
      final dio = Dio();

      // 核心：设置返回类型为 bytes (流)
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      await file.writeAsBytes(response.data);
      return filePath;
    } catch (e) {
      logger.w("通知图片下载失败: $e");
      return null;
    }
  }

  /// 发送通知
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    // 1. 尝试下载头像
    String? largeIconPath;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // 使用简单的文件名，避免特殊字符
      final fileName = 'notif_icon_$id.jpg';
      largeIconPath = await _downloadAndSaveFile(imageUrl, fileName);
    }

    // 2. 配置样式
    // Android: 支持大图和左侧大图标
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_message',
      '聊天消息',
      channelDescription: '收到新消息时的通知',
      importance: Importance.max,
      priority: Priority.high,
      // 如果下载成功，设置大图标 (头像)
      largeIcon:
          largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
    );

    // Linux: 支持图标
    final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      icon: largeIconPath != null ? AssetsLinuxIcon(largeIconPath) : null,
    );

    // Windows: 目前插件主要支持文本，图片支持较弱
    // 但为了代码完整性，我们保持默认配置
    const WindowsNotificationDetails windowsDetails =
        WindowsNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );

    // 3. 显示
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
