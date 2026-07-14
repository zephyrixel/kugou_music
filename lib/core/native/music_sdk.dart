import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/src/rust/api/sdk.dart' as bridge;

abstract interface class MusicSdk {
  Future<SdkCapabilities> initialize();
  Future<AuthSnapshot> authState();
  Future<void> sendSmsCode(String mobile);
  Future<SmsLoginResult> loginBySms(String mobile, String code);
  Future<AuthSnapshot> refreshLogin();
  Future<AuthSnapshot> registerDevice();
  Future<void> logout();
  Future<List<Song>> everydayRecommendations();
  Future<SearchPage> search(String keyword, {int page = 1, int pageSize = 30});
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  });
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  });
  Future<UserProfile> userProfile();
  Future<UserVip> userVip();
  Future<List<Song>> cloudHistory();
  Future<CloudPlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50});
  Future<SearchPage> playlistTracks(
    CloudPlaylist playlist, {
    int page = 1,
    int pageSize = 50,
  });
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  });
  Future<void> createPlaylist(String name, {required bool private});
  Future<void> collectPlaylist(PlaylistSearchHit playlist);
  Future<void> deletePlaylist(CloudPlaylist playlist);
  Future<void> editPlaylist(PlaylistEditInput input);
  Future<void> addSongToPlaylist(int listId, Song song);
  Future<void> removeSongFromPlaylist(int listId, int fileId);
}

class KugouMusicSdk implements MusicSdk {
  KugouMusicSdk(this._storage);

  static const sessionKey = 'kugou_sdk_lite_session_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<SdkCapabilities> initialize() async {
    final persisted = await _storage.read(key: sessionKey);
    if (persisted != null) {
      try {
        await bridge.importSession(value: persisted);
      } catch (_) {
        await _storage.delete(key: sessionKey);
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
      playlistSearch: value.playlistSearch,
      dailyRecommendation: value.dailyRecommendation,
      smsAuth: value.smsAuth,
      cloudLibrary: value.cloudLibrary,
      playlistMutations: value.playlistMutations,
    );
  }

  @override
  Future<AuthSnapshot> authState() async => _auth(await bridge.getAuthState());

  @override
  Future<void> sendSmsCode(String mobile) =>
      _guard(() => bridge.sendSmsCode(mobile: mobile), persist: true);

  @override
  Future<SmsLoginResult> loginBySms(String mobile, String code) =>
      _guard(() async {
        final value = await bridge.loginBySms(mobile: mobile, code: code);
        return SmsLoginResult(
          auth: _auth(value.auth),
          fingerprintWarning: value.fingerprintWarning,
        );
      }, persist: true);

  @override
  Future<AuthSnapshot> refreshLogin() =>
      _guard(() async => _auth(await bridge.refreshLogin()), persist: true);

  @override
  Future<AuthSnapshot> registerDevice() =>
      _guard(() async => _auth(await bridge.registerDevice()), persist: true);

  @override
  Future<void> logout() => _guard(() async {
    await bridge.logout();
    await _persistSession();
  });

  @override
  Future<List<Song>> everydayRecommendations() => _guard(() async {
    final result = await bridge.getEverydayRecommendations();
    await _persistSession();
    return result.songs.map(_songFromDto).toList(growable: false);
  });

  @override
  Future<SearchPage> search(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) => _guard(() async {
    final result = await bridge.searchSongs(
      request: bridge.SearchRequestDto(
        keyword: keyword,
        page: page,
        pageSize: pageSize,
      ),
    );
    await _persistSession();
    return SearchPage(
      songs: result.items.map(_songFromDto).toList(growable: false),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    );
  });

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) => _guard(() async {
    final result = await bridge.searchPlaylists(
      request: bridge.SearchRequestDto(
        keyword: keyword,
        page: page,
        pageSize: pageSize,
      ),
    );
    return PlaylistSearchPage(
      items: result.items.map(_searchHit).toList(growable: false),
      page: result.page,
      pageSize: result.pageSize,
      total: result.total,
    );
  });

  @override
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  }) => _guard(() async {
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
      playable: (url, artworkUrl, quality, bitRate, durationSecs) =>
          PlayableResolution(
            url: url,
            artworkUrl: artworkUrl,
            quality: _audioQuality(quality),
            bitRate: bitRate,
            durationSecs: durationSecs,
          ),
      preview: (url, artworkUrl, quality, endMs, bitRate, durationSecs) =>
          PreviewResolution(
            url: url,
            artworkUrl: artworkUrl,
            quality: _audioQuality(quality),
            endMs: endMs,
            bitRate: bitRate,
            durationSecs: durationSecs,
          ),
      denied: (status, failProcess) =>
          DeniedResolution(status: status, failProcess: failProcess),
      unavailable: UnavailableResolution.new,
    );
  });

  @override
  Future<UserProfile> userProfile() => _guard(() async {
    final value = await bridge.getUserProfile();
    return UserProfile(
      userId: value.userId,
      displayName: value.displayName,
      username: value.username,
      avatarUrl: value.avatarUrl,
      gender: value.gender,
      birthday: value.birthday,
      city: value.city,
      province: value.province,
      signature: value.signature,
      followingCount: value.followingCount,
      fanCount: value.fanCount,
      visitorCount: value.visitorCount,
    );
  });

  @override
  Future<UserVip> userVip() => _guard(() async {
    final value = await bridge.getUserVip();
    return UserVip(
      vipType: value.vipType,
      musicPackageType: value.musicPackageType,
      yearlyType: value.yearlyType,
      vipEndTime: value.vipEndTime,
      musicEndTime: value.musicEndTime,
      yearlyEndTime: value.yearlyEndTime,
      productType: value.productType,
    );
  });

  @override
  Future<List<Song>> cloudHistory() => _guard(() async {
    final value = await bridge.getCloudHistory();
    return value.items.map(_songFromDto).toList(growable: false);
  });

  @override
  Future<CloudPlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50}) =>
      _guard(() async {
        final value = await bridge.getCloudPlaylists(
          page: page,
          pageSize: pageSize,
        );
        return CloudPlaylistPage(
          items: value.items.map(_playlist).toList(growable: false),
          page: value.page,
          pageSize: value.pageSize,
          total: value.total,
          totalVersion: value.totalVersion,
        );
      });

  @override
  Future<SearchPage> playlistTracks(
    CloudPlaylist playlist, {
    int page = 1,
    int pageSize = 50,
  }) => _tracks(
    bridge.PlaylistTracksRequestDto(
      listId: playlist.listId,
      globalCollectionId: playlist.globalCollectionId,
      owned: !playlist.isCollected,
      page: page,
      pageSize: pageSize,
    ),
  );

  @override
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  }) => _tracks(
    bridge.PlaylistTracksRequestDto(
      globalCollectionId: globalCollectionId,
      owned: false,
      page: page,
      pageSize: pageSize,
    ),
  );

  Future<SearchPage> _tracks(bridge.PlaylistTracksRequestDto request) =>
      _guard(() async {
        final value = await bridge.getPlaylistTracks(request: request);
        return SearchPage(
          songs: value.items.map(_songFromDto).toList(growable: false),
          page: value.page,
          pageSize: value.pageSize,
          total: value.total,
        );
      });

  @override
  Future<void> createPlaylist(String name, {required bool private}) => _guard(
    () => bridge.createCloudPlaylist(name: name, private: private),
    persist: true,
  );

  @override
  Future<void> collectPlaylist(PlaylistSearchHit playlist) => _guard(
    () => bridge.collectCloudPlaylist(
      globalCollectionId: playlist.globalCollectionId!,
      ownerUserId: playlist.creatorUserId,
      name: playlist.name,
    ),
    persist: true,
  );

  @override
  Future<void> deletePlaylist(CloudPlaylist playlist) => _guard(
    () => bridge.deleteCloudPlaylist(
      listId: playlist.listId!,
      collected: playlist.isCollected,
    ),
    persist: true,
  );

  @override
  Future<void> editPlaylist(PlaylistEditInput input) => _guard(
    () => bridge.editCloudPlaylist(
      input: bridge.PlaylistEditInputDto(
        listId: input.listId,
        name: input.name,
        private: input.private,
        intro: input.intro,
        tags: input.tags,
        totalVersion: input.totalVersion,
      ),
    ),
    persist: true,
  );

  @override
  Future<void> addSongToPlaylist(int listId, Song song) => _guard(
    () => bridge.addSongToPlaylist(listId: listId, song: _songToDto(song)),
    persist: true,
  );

  @override
  Future<void> removeSongFromPlaylist(int listId, int fileId) => _guard(
    () => bridge.removeSongFromPlaylist(listId: listId, fileId: fileId),
    persist: true,
  );

  Future<T> _guard<T>(
    Future<T> Function() action, {
    bool persist = false,
  }) async {
    try {
      final value = await action();
      if (persist) await _persistSession();
      return value;
    } on bridge.BridgeError catch (error) {
      throw MusicSdkException(
        error.message,
        retryable: error.retryable,
        expired: error.kind == bridge.BridgeErrorKind.authenticationExpired,
        authenticationRequired:
            error.kind == bridge.BridgeErrorKind.authenticationRequired,
        code: error.code,
      );
    }
  }

  Future<void> _persistSession() async {
    final value = await bridge.exportSession();
    await _storage.write(key: sessionKey, value: value);
  }
}

AuthSnapshot _auth(bridge.AuthStateDto value) => AuthSnapshot(
  authenticated: value.authenticated,
  userId: value.userId,
  vipType: value.vipType,
  fingerprintRegistered: value.fingerprintRegistered,
);

AudioQuality _audioQuality(bridge.AudioQualityDto value) => switch (value) {
  bridge.AudioQualityDto.standard => AudioQuality.standard,
  bridge.AudioQualityDto.high => AudioQuality.high,
  bridge.AudioQualityDto.flac => AudioQuality.flac,
  bridge.AudioQualityDto.hiRes => AudioQuality.hiRes,
  bridge.AudioQualityDto.super_ => AudioQuality.superQuality,
};

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
  fileId: value.fileId,
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
  fileId: value.fileId,
  hashes: bridge.AudioHashesDto(
    standard: value.hashes.standard,
    high: value.hashes.high,
    flac: value.hashes.flac,
    hiRes: value.hashes.hiRes,
    superHash: value.hashes.superHash,
  ),
);

CloudPlaylist _playlist(bridge.CloudPlaylistDto value) => CloudPlaylist(
  listId: value.listId,
  globalCollectionId: value.globalCollectionId,
  name: value.name,
  intro: value.intro,
  artworkUrl: value.artworkUrl,
  count: value.count,
  listType: value.listType,
  creatorUserId: value.creatorUserId,
  creatorName: value.creatorName,
  isPrivate: value.isPrivate,
  isMyFavorite: value.isMyFavorite,
  isDefaultCollect: value.isDefaultCollect,
  tags: value.tags,
);

PlaylistSearchHit _searchHit(bridge.PlaylistSearchHitDto value) =>
    PlaylistSearchHit(
      specialId: value.specialId,
      globalCollectionId: value.globalCollectionId,
      name: value.name,
      intro: value.intro,
      artworkUrl: value.artworkUrl,
      songCount: value.songCount,
      playCount: value.playCount,
      collectCount: value.collectCount,
      creatorName: value.creatorName,
      creatorUserId: value.creatorUserId,
      tags: value.tags,
    );

class SdkCapabilities {
  const SdkCapabilities({
    required this.platform,
    required this.songSearch,
    required this.playlistSearch,
    required this.dailyRecommendation,
    required this.smsAuth,
    required this.cloudLibrary,
    required this.playlistMutations,
  });
  final String platform;
  final bool songSearch;
  final bool playlistSearch;
  final bool dailyRecommendation;
  final bool smsAuth;
  final bool cloudLibrary;
  final bool playlistMutations;
}

class SearchPage {
  const SearchPage({
    required this.songs,
    required this.page,
    required this.pageSize,
    this.total,
  });
  final List<Song> songs;
  final int page;
  final int pageSize;
  final int? total;
}

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
  const DeniedResolution({this.status, this.failProcess});
  final int? status;
  final int? failProcess;
}

class UnavailableResolution extends PlaybackResolution {
  const UnavailableResolution();
}

class MusicSdkException implements Exception {
  const MusicSdkException(
    this.message, {
    this.retryable = false,
    this.expired = false,
    this.authenticationRequired = false,
    this.code,
  });
  final String message;
  final bool retryable;
  final bool expired;
  final bool authenticationRequired;
  final int? code;

  @override
  String toString() => message;
}
