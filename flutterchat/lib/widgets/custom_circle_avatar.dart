import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. 引入 Riverpod
import 'package:flutterchat/providers/services_provider.dart'; // 引入 apiServiceProvider
import 'package:flutterchat/utils/custom_cache_manager.dart';

// 2. 改为继承 ConsumerWidget
class CustomCircleAvatar extends ConsumerWidget {
  /// 可能是完整的 URL (http...)，也可能只是 MinIO 的 Object Key
  final String? avatarUrl;

  /// 头像的半径
  final double radius;

  /// 当没有头像时，占位符图标的大小
  final double iconSize;

  const CustomCircleAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20.0,
  }) : iconSize = radius * 1.2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 判断是否有效
    final bool hasValidUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    // 3. 使用 Riverpod 获取 ApiService
    // 注意：这里使用 read 即可，因为 URL 转换逻辑不需要监听变化
    final apiService = ref.read(apiServiceProvider);

    // 构建完整 URL
    String fullUrl = '';
    if (hasValidUrl) {
      if (avatarUrl!.startsWith('http')) {
        fullUrl = avatarUrl!;
      } else {
        // 使用 Provider 中的方法，确保 BaseUrl 配置正确
        fullUrl = apiService.getFullAvatarUrl(avatarUrl);
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2E2E2E), // 稍微深一点的灰色，更适配深色模式

      // 如果没有 URL，显示默认图标
      child: !hasValidUrl
          ? Icon(Icons.person, size: iconSize, color: Colors.white54)
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                // 使用自定义缓存管理器
                cacheManager: CustomCacheManager.instance,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,

                // 渐变显示，体验更好
                fadeInDuration: const Duration(milliseconds: 200),

                // 加载中
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  padding: const EdgeInsets.all(2),
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white30),
                  ),
                ),

                // 加载失败 (比如 404 或 网络错误)
                errorWidget: (context, url, error) {
                  // 可以在这里打印日志方便调试
                  // print("图片加载失败: $url, error: $error");
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.person,
                      size: iconSize,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
