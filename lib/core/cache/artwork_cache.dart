import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ArtworkCacheManager extends CacheManager with ImageCacheManager {
  ArtworkCacheManager._()
    : super(
        Config(
          'kgmusic_artwork_v1',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 800,
        ),
      );

  static final instance = ArtworkCacheManager._();
}

class ArtworkCacheService {
  ArtworkCacheService._();

  static final instance = ArtworkCacheService._();

  ArtworkCacheManager get manager => ArtworkCacheManager.instance;

  String cacheKey({
    required String url,
    String? cacheId,
    required int pixelSize,
  }) {
    final uri = Uri.tryParse(url);
    final canonicalUrl = uri == null
        ? url
        : '${uri.scheme}://${uri.host}${uri.path}';
    final identity = '${cacheId ?? canonicalUrl}|$canonicalUrl|$pixelSize';
    return 'kgmusic-artwork-${sha256.convert(utf8.encode(identity))}';
  }

  Future<File> getFile({
    required String url,
    String? cacheId,
    required int pixelSize,
  }) => manager.getSingleFile(
    url,
    key: cacheKey(url: url, cacheId: cacheId, pixelSize: pixelSize),
  );

  Future<void> clear() => manager.emptyCache();
}
