import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/database/app_database.dart';

class CacheCoordinator {
  const CacheCoordinator(this._database, this._audioCache);

  final AppDatabase _database;
  final AudioCacheManager _audioCache;

  Future<void> clearTransientCaches() async {
    await Future.wait([
      _database.clearResponseCache(),
      _audioCache.clear(),
      ArtworkCacheService.instance.clear(),
    ]);
  }
}
