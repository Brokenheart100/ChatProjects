import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const key = 'customCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      // 核心配置：定义缓存的行为
      stalePeriod: const Duration(days: 15), // 缓存有效期，例如15天
      maxNrOfCacheObjects: 100, // 最多缓存100个对象

      // 关键！我们不需要 fileService，让它自己处理 HTTP 请求
      // fileService: HttpFileService(),
    ),
  );
}
