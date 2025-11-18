import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutterchat/services/api_service.dart';
import 'package:flutterchat/utils/custom_cache_manager.dart'; // 引入我们自定义的缓存管理器

class CustomCircleAvatar extends StatelessWidget {
  /// 可能是完整的 URL，也可能只是 MinIO 的 Object Key
  final String? avatarUrl;

  /// 头像的半径
  final double radius;

  /// 当没有头像时，占位符图标的大小
  final double iconSize;

  /// ApiService 的实例，用于构建完整的 URL
  /// 我们通过一个静态实例来避免在每个地方都创建它
  static final ApiService _apiService = ApiService();

  const CustomCircleAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20.0, // 提供一个默认半径
  }) : iconSize = radius * 1.2; // 动态计算图标大小，使其看起来协调

  @override
  Widget build(BuildContext context) {
    // 判断 URL 是否有效
    final bool hasValidUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    // 如果 URL 是 http 开头，则认为是完整的 URL；否则，认为是 Object Key，需要构建
    final String fullUrl = hasValidUrl
        ? (avatarUrl!.startsWith('http')
            ? avatarUrl!
            : _apiService.getFullAvatarUrl(avatarUrl))
        : '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade800, // 统一的背景/占位符颜色
      // 如果没有有效的 URL，直接显示占位符图标
      child: !hasValidUrl
          ? Icon(Icons.person, size: iconSize, color: Colors.white54)
          : ClipOval(
              // 使用 ClipOval 来确保网络图片是圆形的
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                cacheManager: CustomCacheManager.instance, // 使用我们的自定义缓存
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                // 加载中的占位符
                placeholder: (context, url) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70),
                  ),
                ),
                // 加载失败的占位符
                errorWidget: (context, url, error) => Icon(
                  Icons.person, // 失败时也显示人物图标
                  size: iconSize,
                  color: Colors.white54,
                ),
              ),
            ),
    );
  }
}
