import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const key = 'customCacheKey';

  // 使用单例模式，确保全局共用一个缓存管理器
  static final CacheManager instance = CacheManager(
    Config(
      key,
      // 缓存配置
      stalePeriod: const Duration(days: 15), // 缓存有效期 15 天
      maxNrOfCacheObjects: 200, // 稍微调大一点，聊天头像可能很多
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
