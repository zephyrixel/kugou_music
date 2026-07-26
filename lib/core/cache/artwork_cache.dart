import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ArtworkCacheManager extends CacheManager {
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

  /// Kugou `{size}` templates are substituted into the request URL, so an
  /// unquantized pixel size makes every layout width its own download *and*
  /// its own cache entry. Snapping to a short ladder lets the list thumbnail,
  /// the player, the backdrop and the notification prefetch share one file.
  static const sizeLadder = <int>[240, 480, 720, 1080];

  /// Rounds up to the next rung so a widget never renders below its own size.
  static int snapPixelSize(int pixelSize) {
    for (final rung in sizeLadder) {
      if (pixelSize <= rung) return rung;
    }
    return sizeLadder.last;
  }

  ArtworkCacheManager get manager => ArtworkCacheManager.instance;

  /// Keyed on the resource identity plus the ladder rung. The query string is
  /// dropped because it carries rotating CDN tokens; the rung stays because it
  /// is substituted into the request URL and so changes the stored bytes.
  String cacheKey({
    required String url,
    String? cacheId,
    required int pixelSize,
  }) {
    final uri = Uri.tryParse(url);
    final canonicalUrl = uri == null
        ? url
        : '${uri.scheme}://${uri.host}${uri.path}';
    final rung = snapPixelSize(pixelSize);
    final identity = '${cacheId ?? canonicalUrl}|$canonicalUrl|$rung';
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
