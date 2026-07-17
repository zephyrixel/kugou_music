import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/logging/app_log.dart';

class CacheCoordinator {
  const CacheCoordinator(this._database, this._audioCache);

  final AppDatabase _database;
  final AudioCacheManager _audioCache;

  Future<void> clearTransientCaches() async {
    try {
      await Future.wait([
        _database.clearResponseCache(),
        _audioCache.clear(),
        ArtworkCacheService.instance.clear(),
      ]);
    } catch (error, stackTrace) {
      AppLog.warn(
        '清理临时缓存失败',
        target: 'cache',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
