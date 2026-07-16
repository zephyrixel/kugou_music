enum CacheLoadMode { normal, forceRefresh }

class CachePolicy {
  const CachePolicy({
    required this.freshFor,
    this.minimumRequestGap = const Duration(seconds: 2),
  });

  final Duration freshFor;
  final Duration minimumRequestGap;

  bool isFresh(DateTime updatedAt, DateTime now) =>
      now.difference(updatedAt) < freshFor;
}

abstract final class MusicCachePolicies {
  static const daily = CachePolicy(freshFor: Duration(hours: 6));
  static const profile = CachePolicy(freshFor: Duration(minutes: 30));
  static const vip = CachePolicy(freshFor: Duration(minutes: 10));
  static const search = CachePolicy(freshFor: Duration(minutes: 10));
  static const publicPlaylist = CachePolicy(freshFor: Duration(minutes: 15));
}
