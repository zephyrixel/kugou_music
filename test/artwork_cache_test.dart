import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';

void main() {
  final service = ArtworkCacheService.instance;

  test('artwork cache ignores query tokens but separates paths', () {
    final first = service.cacheKey(
      url: 'https://img.example.com/cover.jpg?token=one',
      cacheId: 'song:42',
      pixelSize: 240,
    );
    final rotatedToken = service.cacheKey(
      url: 'https://img.example.com/cover.jpg?token=two',
      cacheId: 'song:42',
      pixelSize: 240,
    );
    final changedPath = service.cacheKey(
      url: 'https://img.example.com/new-cover.jpg?token=two',
      cacheId: 'song:42',
      pixelSize: 240,
    );

    expect(rotatedToken, first);
    expect(changedPath, isNot(first));
  });

  test('同一封面的相邻显示尺寸共享一个缓存键', () {
    // List thumbnail (52dp), mini player (48dp) and queue row (44dp) all land
    // on the 240 rung, so one download serves every list surface.
    final keys = [240, 132, 168, 216]
        .map(
          (size) => service.cacheKey(
            url: 'https://img.example.com/cover.jpg',
            cacheId: 'song:42',
            pixelSize: size,
          ),
        )
        .toSet();

    expect(keys, hasLength(1));
  });

  test('跨档位的尺寸仍然分开缓存', () {
    final small = service.cacheKey(
      url: 'https://img.example.com/cover.jpg',
      cacheId: 'song:42',
      pixelSize: 240,
    );
    final large = service.cacheKey(
      url: 'https://img.example.com/cover.jpg',
      cacheId: 'song:42',
      pixelSize: 720,
    );

    expect(large, isNot(small));
  });

  test('尺寸向上取整到档位，不会低于控件自身尺寸', () {
    expect(ArtworkCacheService.snapPixelSize(64), 240);
    expect(ArtworkCacheService.snapPixelSize(240), 240);
    expect(ArtworkCacheService.snapPixelSize(241), 480);
    expect(ArtworkCacheService.snapPixelSize(720), 720);
    // The player prefetch rung is reused verbatim by the full-screen cover.
    expect(ArtworkCacheService.snapPixelSize(1080), 1080);
    expect(ArtworkCacheService.snapPixelSize(4096), 1080);
  });
}
