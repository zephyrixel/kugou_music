import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';

void main() {
  test('artwork cache ignores query tokens but separates paths and sizes', () {
    final service = ArtworkCacheService.instance;
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
    final large = service.cacheKey(
      url: 'https://img.example.com/cover.jpg?token=two',
      cacheId: 'song:42',
      pixelSize: 720,
    );

    expect(rotatedToken, first);
    expect(changedPath, isNot(first));
    expect(large, isNot(first));
  });
}
