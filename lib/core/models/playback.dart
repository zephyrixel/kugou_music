import 'package:kgmusic/core/models/song.dart';

enum AudioQuality { standard, high, flac, hiRes, superQuality }

extension AudioQualityInfo on AudioQuality {
  String get label => switch (this) {
    AudioQuality.standard => '标准',
    AudioQuality.high => '高品',
    AudioQuality.flac => '无损',
    AudioQuality.hiRes => 'Hi-Res',
    AudioQuality.superQuality => 'DSD',
  };

  String get detail => switch (this) {
    AudioQuality.standard => '约 128 kbps',
    AudioQuality.high => '约 320 kbps',
    AudioQuality.flac => 'FLAC 无损',
    AudioQuality.hiRes => '高解析度音频',
    AudioQuality.superQuality => 'Super/DSD 资源',
  };

  bool isAvailableFor(Song song) {
    return hashFor(song)?.trim().isNotEmpty == true;
  }

  String? hashFor(Song song) {
    return switch (this) {
      AudioQuality.standard => song.hashes.standard,
      AudioQuality.high => song.hashes.high,
      AudioQuality.flac => song.hashes.flac,
      AudioQuality.hiRes => song.hashes.hiRes,
      AudioQuality.superQuality => song.hashes.superHash,
    };
  }
}

sealed class PlaybackResolution {
  const PlaybackResolution();
}

class PlayableResolution extends PlaybackResolution {
  const PlayableResolution({
    required this.url,
    required this.quality,
    this.artworkUrl,
    this.bitRate,
    this.durationSecs,
  });
  final String url;
  final AudioQuality quality;
  final String? artworkUrl;
  final int? bitRate;
  final int? durationSecs;
}

class PreviewResolution extends PlayableResolution {
  const PreviewResolution({
    required super.url,
    required super.quality,
    super.artworkUrl,
    super.bitRate,
    super.durationSecs,
    this.endMs,
  });
  final int? endMs;
}

class DeniedResolution extends PlaybackResolution {
  const DeniedResolution();
}

class UnavailableResolution extends PlaybackResolution {
  const UnavailableResolution();
}
