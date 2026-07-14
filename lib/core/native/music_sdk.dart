import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/src/rust/api/sdk.dart' as bridge;

abstract interface class MusicSdk {
  Future<SdkCapabilities> initialize();
  Future<List<Song>> everydayRecommendations();
  Future<SearchPage> search(String keyword, {int page = 1, int pageSize = 30});
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  });
}

class KugouMusicSdk implements MusicSdk {
  KugouMusicSdk(this._storage);

  static const _sessionKey = 'kugou_sdk_lite_session_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<SdkCapabilities> initialize() async {
    final persisted = await _storage.read(key: _sessionKey);
    if (persisted != null) {
      try {
        await bridge.importSession(value: persisted);
      } catch (_) {
        await _storage.delete(key: _sessionKey);
      }
    }

    final value = await bridge.initializeSdk();
    if (value.platform != 'lite') {
      throw const MusicSdkException('SDK 返回了非 Lite 平台，已拒绝启动');
    }
    await _persistSession();
    return SdkCapabilities(
      platform: value.platform,
      songSearch: value.songSearch,
      dailyRecommendation: value.dailyRecommendation,
      trendingPlaylists: value.trendingPlaylists,
    );
  }

  @override
  Future<List<Song>> everydayRecommendations() async {
    try {
      final result = await bridge.getEverydayRecommendations();
      await _persistSession();
      return result.songs
          .map(_songFromDto)
          .map((song) => song.copyWith(artworkUrl: result.artworkUrl))
          .toList(growable: false);
    } on bridge.BridgeError catch (error) {
      throw MusicSdkException(error.message, retryable: error.retryable);
    }
  }

  @override
  Future<SearchPage> search(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final result = await bridge.searchSongs(
        request: bridge.SearchSongsRequestDto(
          keyword: keyword,
          page: page,
          pageSize: pageSize,
        ),
      );
      await _persistSession();
      return SearchPage(
        songs: result.items.map(_songFromDto).toList(growable: false),
        page: result.page,
        total: result.total,
      );
    } on bridge.BridgeError catch (error) {
      throw MusicSdkException(error.message, retryable: error.retryable);
    }
  }

  @override
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  }) async {
    try {
      final value = await bridge.resolvePlayback(
        request: bridge.ResolvePlaybackRequestDto(
          song: _songToDto(song),
          quality: switch (quality) {
            AudioQuality.standard => bridge.AudioQualityDto.standard,
            AudioQuality.high => bridge.AudioQualityDto.high,
            AudioQuality.flac => bridge.AudioQualityDto.flac,
            AudioQuality.hiRes => bridge.AudioQualityDto.hiRes,
            AudioQuality.superQuality => bridge.AudioQualityDto.super_,
          },
          freePreview: freePreview,
        ),
      );
      await _persistSession();
      return value.when(
        playable: (url, bitRate, durationSecs) => PlayableResolution(
          url: url,
          bitRate: bitRate,
          durationSecs: durationSecs,
        ),
        preview: (url, endMs, bitRate, durationSecs) => PreviewResolution(
          url: url,
          endMs: endMs,
          bitRate: bitRate,
          durationSecs: durationSecs,
        ),
        denied: (status, failProcess) =>
            DeniedResolution(status: status, failProcess: failProcess),
        unavailable: UnavailableResolution.new,
      );
    } on bridge.BridgeError catch (error) {
      throw MusicSdkException(error.message, retryable: error.retryable);
    }
  }

  Future<void> _persistSession() async {
    final value = await bridge.exportSession();
    await _storage.write(key: _sessionKey, value: value);
  }
}

Song _songFromDto(bridge.SongDto value) => Song(
  id: value.id,
  title: value.title,
  artist: value.artist,
  album: value.album,
  durationSecs: value.durationSecs,
  artworkUrl: value.artworkUrl,
  privilege: value.privilege,
  albumId: value.albumId,
  mixSongId: value.mixSongId,
  hashes: AudioHashes(
    standard: value.hashes.standard,
    high: value.hashes.high,
    flac: value.hashes.flac,
    hiRes: value.hashes.hiRes,
    superHash: value.hashes.superHash,
  ),
);

bridge.SongDto _songToDto(Song value) => bridge.SongDto(
  id: value.id,
  title: value.title,
  artist: value.artist,
  album: value.album,
  durationSecs: value.durationSecs,
  artworkUrl: value.artworkUrl,
  privilege: value.privilege,
  albumId: value.albumId,
  mixSongId: value.mixSongId,
  hashes: bridge.AudioHashesDto(
    standard: value.hashes.standard,
    high: value.hashes.high,
    flac: value.hashes.flac,
    hiRes: value.hashes.hiRes,
    superHash: value.hashes.superHash,
  ),
);

class SdkCapabilities {
  const SdkCapabilities({
    required this.platform,
    required this.songSearch,
    required this.dailyRecommendation,
    required this.trendingPlaylists,
  });

  final String platform;
  final bool songSearch;
  final bool dailyRecommendation;
  final bool trendingPlaylists;
}

class SearchPage {
  const SearchPage({required this.songs, required this.page, this.total});
  final List<Song> songs;
  final int page;
  final int? total;
}

enum AudioQuality { standard, high, flac, hiRes, superQuality }

sealed class PlaybackResolution {
  const PlaybackResolution();
}

class PlayableResolution extends PlaybackResolution {
  const PlayableResolution({
    required this.url,
    this.bitRate,
    this.durationSecs,
  });
  final String url;
  final int? bitRate;
  final int? durationSecs;
}

class PreviewResolution extends PlayableResolution {
  const PreviewResolution({
    required super.url,
    super.bitRate,
    super.durationSecs,
    this.endMs,
  });
  final int? endMs;
}

class DeniedResolution extends PlaybackResolution {
  const DeniedResolution({this.status, this.failProcess});
  final int? status;
  final int? failProcess;
}

class UnavailableResolution extends PlaybackResolution {
  const UnavailableResolution();
}

class MusicSdkException implements Exception {
  const MusicSdkException(this.message, {this.retryable = false});
  final String message;
  final bool retryable;

  @override
  String toString() => message;
}
