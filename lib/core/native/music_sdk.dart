import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';
import 'package:kgmusic/core/native/secure_session_store.dart';
import 'package:kgmusic/core/native/rust_bridge.dart' as bridge;
import 'package:kgmusic/core/platform/device_profile.dart';

abstract interface class AuthSdk {
  Future<void> initialize();
  Future<AuthSnapshot> authState();
  Future<void> sendSmsCode(String mobile);
  Future<SmsLoginResult> loginBySms(String mobile, String code);
  Future<AuthSnapshot> refreshLogin();
  Future<AuthSnapshot> ensureDeviceRegistered();
  Future<AuthSnapshot> registerDevice();
  Future<void> logout();
}

abstract interface class BrowseSdk {
  Future<List<Song>> everydayRecommendations();
  Future<SearchPage> search(String keyword, {int page = 1, int pageSize = 30});
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  });
  Future<UserProfile> userProfile();
  Future<UserVip> userVip();
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  });
}

abstract interface class RecommendationSdk {
  Future<RecommendationBatch> personalFm(PersonalFmInput input);
  Future<RecommendationBatch> heartRadio({
    List<int> currentMixSongIds = const [],
  });
  Future<RecommendationReportAck> reportRecommendationHistory(
    List<RecommendationHistoryEvent> items, {
    int? previousSyncPoint,
  });
  Future<void> reportRecommendationRepeated(
    List<String> hashes, {
    required int remainSongCount,
  });
  Future<void> reportRecommendationFavoriteClick(Song song);
}

abstract interface class PlaybackSdk {
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  });
}

abstract interface class PlayerSdk implements AuthSdk, PlaybackSdk {}

abstract interface class MembershipSdk {
  Future<UserVip> userVip();
  Future<VipClaimResult> claimDayVip();
  Future<VipUpgradeResult> upgradeDayVip();
  Future<VipMonthRecord> monthVipRecord();
}

abstract interface class LibrarySdk {
  Future<HistoryPage> cloudHistory({String? cursor});
  Future<void> uploadHistory(List<HistoryUpload> items);
  Future<PlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50});
  Future<SearchPage> playlistTracks(
    Playlist playlist, {
    int page = 1,
    int pageSize = 50,
  });
  Future<SearchPage> playlistTracksByListId(
    int listId, {
    int page = 1,
    int pageSize = 50,
  });
  Future<PlaylistMutation> createPlaylist(String name, {required bool private});
  Future<PlaylistMutation> collectPlaylist(PlaylistSearchHit playlist);
  Future<void> deletePlaylist({required int listId, required bool collected});
  Future<void> editPlaylist(PlaylistEditInput input);
  Future<PlaylistTracksMutation> addSongToPlaylist(int listId, Song song);
  Future<void> removeSongFromPlaylist(int listId, int fileId);
}

abstract interface class MusicSdk
    implements
        PlayerSdk,
        BrowseSdk,
        RecommendationSdk,
        MembershipSdk,
        LibrarySdk {}

class KugouMusicSdk implements MusicSdk, LyricsSdk {
  KugouMusicSdk(
    FlutterSecureStorage storage, {
    DeviceProfileSource? deviceProfiles,
  }) : _storage = storage,
       _deviceProfiles = deviceProfiles ?? AndroidDeviceProfileSource(storage),
       _sessions = SecureSessionStore(storage, key: sessionKey);

  static const sessionKey = AuthStorageKeys.sessionV2;
  static const legacySessionKey = AuthStorageKeys.legacySessionV1;
  final FlutterSecureStorage _storage;
  final DeviceProfileSource _deviceProfiles;
  final SecureSessionStore _sessions;

  @override
  Future<void> initialize() async {
    if (await _storage.read(key: legacySessionKey) != null) {
      await _storage.delete(key: legacySessionKey);
      await _storage.write(
        key: AuthStorageKeys.startupNotice,
        value: AuthStartupNotice.securityUpgrade.name,
      );
    }
    final deviceProfile = await _deviceProfiles.read();
    final persisted = await _sessions.read();
    try {
      await bridge.initializeSdk(
        deviceProfile: _deviceProfileDto(deviceProfile),
        persistedSession: persisted,
      );
    } on bridge.BridgeError catch (error) {
      if (persisted == null ||
          error.kind != bridge.BridgeErrorKind.sessionInvalid) {
        rethrow;
      }
      await _sessions.delete();
      await _storage.write(
        key: AuthStorageKeys.startupNotice,
        value: AuthStartupNotice.sessionReset.name,
      );
      await bridge.initializeSdk(
        deviceProfile: _deviceProfileDto(deviceProfile),
      );
    }
    await _persistSession();
  }

  @override
  Future<AuthSnapshot> authState() async => _auth(await bridge.getAuthState());

  @override
  Future<void> sendSmsCode(String mobile) async {
    await ensureDeviceRegistered();
    await _guard(() => bridge.sendSmsCode(mobile: mobile), persist: true);
  }

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
  Future<AuthSnapshot> ensureDeviceRegistered() => _guard(
    () async => _auth(await bridge.ensureDeviceRegistered()),
    persist: true,
  );

  @override
  Future<AuthSnapshot> registerDevice() =>
      _guard(() async => _auth(await bridge.registerDevice()), persist: true);

  @override
  Future<void> logout() => _guard(bridge.logout);

  @override
  Future<List<Song>> everydayRecommendations() => _guard(() async {
    final result = await bridge.getEverydayRecommendations();
    return result.map(_songFromDto).toList(growable: false);
  });

  @override
  Future<RecommendationBatch> personalFm(PersonalFmInput input) =>
      _guard(() async {
        final value = await bridge.getPersonalFm(
          request: bridge.PersonalFmRequestDto(
            action: switch (input.action) {
              PersonalFmAction.play => bridge.PersonalFmActionDto.play,
              PersonalFmAction.skip => bridge.PersonalFmActionDto.skip,
              PersonalFmAction.garbage => bridge.PersonalFmActionDto.garbage,
            },
            currentSong: input.currentSong == null
                ? null
                : _songToDto(input.currentSong!),
            remainSongCount: input.remainSongCount,
            playtimeSecs: input.playtimeSecs,
            markList: input.markList,
            currentMark: input.currentMark,
          ),
        );
        return _recommendationBatch(value);
      });

  @override
  Future<RecommendationBatch> heartRadio({
    List<int> currentMixSongIds = const [],
  }) => _guard(() async {
    final value = await bridge.getHeartRadio(
      request: bridge.HeartRadioRequestDto(
        currentMixSongIds: currentMixSongIds,
      ),
    );
    return _recommendationBatch(value);
  });

  @override
  Future<RecommendationReportAck> reportRecommendationHistory(
    List<RecommendationHistoryEvent> items, {
    int? previousSyncPoint,
  }) => _guard(() async {
    final value = await bridge.reportRecommendationHistory(
      items: items
          .map(
            (item) => bridge.RecommendationHistoryItemDto(
              action: switch (item.action) {
                RecommendationHistoryAction.play =>
                  bridge.RecommendationHistoryActionDto.play,
                RecommendationHistoryAction.collect =>
                  bridge.RecommendationHistoryActionDto.collect,
                RecommendationHistoryAction.trash =>
                  bridge.RecommendationHistoryActionDto.trash,
              },
              song: _songToDto(item.song),
            ),
          )
          .toList(growable: false),
      previousSyncPoint: previousSyncPoint,
    );
    return RecommendationReportAck(
      syncPoint: value.syncPoint,
      isClean: value.isClean,
    );
  });

  @override
  Future<void> reportRecommendationRepeated(
    List<String> hashes, {
    required int remainSongCount,
  }) => _guard(
    () => bridge.reportRecommendationRepeated(
      hashes: hashes,
      remainSongCount: remainSongCount,
    ),
  );

  @override
  Future<void> reportRecommendationFavoriteClick(Song song) => _guard(
    () => bridge.reportRecommendationFavoriteClick(song: _songToDto(song)),
  );

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
      denied: DeniedResolution.new,
      unavailable: UnavailableResolution.new,
    );
  });

  @override
  Future<LyricDocument?> fetchLyrics(Song song) => _guard(() async {
    final value = await bridge.getSongLyrics(song: _songToDto(song));
    return value.when(
      found: (document) => _lyricDocument(document),
      notFound: () => null,
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
      businessType: value.businessType,
      products: value.products
          .map(
            (product) => VipProduct(
              productType: product.productType,
              businessType: product.businessType,
              active: product.active,
              paid: product.paid,
              yearly: product.yearly,
              vipEndTime: product.vipEndTime,
              paidExpireTime: product.paidExpireTime,
            ),
          )
          .toList(growable: false),
    );
  });

  @override
  Future<VipClaimResult> claimDayVip() => _guard(() async {
    final value = await bridge.claimDayVip();
    return VipClaimResult(
      grantedUnits: value.grantedUnits,
      endTime: value.endTime,
      serverTimeSecs: value.serverTimeSecs,
    );
  });

  @override
  Future<VipUpgradeResult> upgradeDayVip() => _guard(() async {
    final value = await bridge.upgradeDayVip();
    return VipUpgradeResult(
      statusCode: value.statusCode,
      message: value.message,
      endTime: value.endTime,
    );
  });

  @override
  Future<VipMonthRecord> monthVipRecord() => _guard(() async {
    final value = await bridge.getMonthVipRecord();
    return VipMonthRecord(
      claimedDays: value.claimedDays,
      claimDates: value.claimDates,
    );
  });

  @override
  Future<HistoryPage> cloudHistory({String? cursor}) => _guard(() async {
    final value = await bridge.getCloudHistory(cursor: cursor);
    return HistoryPage(
      items: value.items
          .map(
            (item) => HistoryEntry(
              song: _songFromDto(item.song),
              playedAt: DateTime.fromMillisecondsSinceEpoch(
                (item.playedAtSecs ?? 0) * 1000,
              ),
              playCount: item.playCount ?? 1,
            ),
          )
          .toList(growable: false),
      cursor: value.cursor,
      hasMore: value.hasMore,
      total: value.total,
    );
  });

  @override
  Future<void> uploadHistory(List<HistoryUpload> items) => _guard(
    () => bridge.uploadCloudHistory(
      items: items
          .map(
            (item) => bridge.HistoryUploadItemDto(
              mixSongId: item.mixSongId,
              playedAtSecs: item.playedAt.millisecondsSinceEpoch ~/ 1000,
              playCount: item.playCount,
            ),
          )
          .toList(growable: false),
    ),
    persist: true,
  );

  @override
  Future<PlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50}) =>
      _guard(() async {
        final value = await bridge.getCloudPlaylists(
          page: page,
          pageSize: pageSize,
        );
        return PlaylistPage(
          items: value.items.map(_playlist).toList(growable: false),
          page: value.page,
          pageSize: value.pageSize,
          total: value.total,
        );
      });

  @override
  Future<SearchPage> playlistTracks(
    Playlist playlist, {
    int page = 1,
    int pageSize = 50,
  }) {
    // Official UI is newest-first. SDK `tracks(gid)` matches that; own-list
    // `tracks_by_listid` is oldest-first. Prefer gid whenever present (0.2.2+).
    final gid = playlist.globalCollectionId?.trim();
    final hasGid = gid != null && gid.isNotEmpty;
    if (hasGid) {
      return _tracksByGid(gid, page: page, pageSize: pageSize);
    }
    final listId = playlist.listId;
    if (listId == null) {
      throw const MusicSdkException('歌单缺少可用的云端标识');
    }
    return _tracksByListId(listId, page: page, pageSize: pageSize);
  }

  @override
  Future<SearchPage> playlistTracksByListId(
    int listId, {
    int page = 1,
    int pageSize = 50,
  }) => _tracksByListId(listId, page: page, pageSize: pageSize);

  @override
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  }) => _tracksByGid(globalCollectionId, page: page, pageSize: pageSize);

  Future<SearchPage> _tracksByGid(
    String globalCollectionId, {
    required int page,
    required int pageSize,
  }) => _guard(() async {
    final value = await bridge.getPlaylistTracksByGid(
      globalCollectionId: globalCollectionId,
      page: page,
      pageSize: pageSize,
    );
    return _searchPage(value);
  });

  Future<SearchPage> _tracksByListId(
    int listId, {
    required int page,
    required int pageSize,
  }) => _guard(() async {
    final value = await bridge.getPlaylistTracksByListId(
      listId: listId,
      page: page,
      pageSize: pageSize,
    );
    return _searchPage(value);
  });

  @override
  Future<PlaylistMutation> createPlaylist(
    String name, {
    required bool private,
  }) => _guard(() async {
    final value = await bridge.createCloudPlaylist(
      name: name,
      private: private,
    );
    return PlaylistMutation(
      listId: value.listId,
      globalCollectionId: value.globalCollectionId,
    );
  }, persist: true);

  @override
  Future<PlaylistMutation> collectPlaylist(PlaylistSearchHit playlist) =>
      _guard(() async {
        final value = await bridge.collectCloudPlaylist(
          globalCollectionId: playlist.globalCollectionId!,
          ownerUserId: playlist.creatorUserId,
          name: playlist.name,
        );
        return PlaylistMutation(
          listId: value.listId,
          globalCollectionId: value.globalCollectionId,
        );
      }, persist: true);

  @override
  Future<void> deletePlaylist({required int listId, required bool collected}) =>
      _guard(
        () => bridge.deleteCloudPlaylist(listId: listId, collected: collected),
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
      ),
    ),
    persist: true,
  );

  @override
  Future<PlaylistTracksMutation> addSongToPlaylist(int listId, Song song) =>
      _guard(() async {
        final value = await bridge.addSongToPlaylist(
          listId: listId,
          song: _songToDto(song),
        );
        return PlaylistTracksMutation(fileIds: value.fileIds);
      }, persist: true);

  @override
  Future<void> removeSongFromPlaylist(int listId, int fileId) => _guard(
    () => bridge.removeSongFromPlaylist(listId: listId, fileId: fileId),
    persist: true,
  );

  Future<T> _guard<T>(
    Future<T> Function() action, {
    bool persist = true,
  }) async {
    try {
      final value = await action();
      if (persist) await _persistSession();
      return value;
    } on bridge.BridgeError catch (error, stackTrace) {
      final exception = MusicSdkException(
        error.message,
        retryable: error.retryable,
        expired: error.kind == bridge.BridgeErrorKind.authenticationExpired,
        authenticationRequired:
            error.kind == bridge.BridgeErrorKind.authenticationRequired,
        code: error.code,
      );
      if (persist) {
        try {
          await _persistSession();
        } catch (_) {
          // Preserve the original SDK failure; the next successful call will
          // persist the latest in-memory session again.
        }
      }
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  Future<void> _persistSession() async {
    final value = await bridge.exportSession();
    await _sessions.writeIfChanged(value);
  }
}

SearchPage _searchPage(bridge.SongPageDto value) => SearchPage(
  songs: value.items.map(_songFromDto).toList(growable: false),
  page: value.page,
  pageSize: value.pageSize,
  total: value.total,
);

AuthSnapshot _auth(bridge.AuthStateDto value) => AuthSnapshot(
  authenticated: value.authenticated,
  userId: value.userId,
  vipType: value.vipType,
  fingerprintRegistered: value.fingerprintRegistered,
);

bridge.DeviceProfileDto _deviceProfileDto(DeviceProfile value) =>
    bridge.DeviceProfileDto(
      deviceId: value.deviceId,
      androidId: value.androidId,
      brand: value.brand,
      model: value.model,
      manufacturer: value.manufacturer,
      basebandVersion: value.basebandVersion,
      availableRamBytes: value.availableRamBytes,
      availableInternalStorageBytes: value.availableInternalStorageBytes,
      availableExternalStorageBytes: value.availableExternalStorageBytes,
      batteryLevel: value.batteryLevel,
      batteryStatus: value.batteryStatus,
      hasAccelerometer: value.hasAccelerometer,
      hasGravity: value.hasGravity,
      hasGyroscope: value.hasGyroscope,
      hasLight: value.hasLight,
      hasMagneticField: value.hasMagneticField,
      hasOrientation: value.hasOrientation,
      hasPressure: value.hasPressure,
      hasStepCounter: value.hasStepCounter,
      hasAmbientTemperature: value.hasAmbientTemperature,
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

LyricDocument _lyricDocument(bridge.LyricDocumentDto value) => LyricDocument(
  format: switch (value.format) {
    bridge.LyricFormatDto.krc => LyricFormat.krc,
    bridge.LyricFormatDto.lrc => LyricFormat.lrc,
    bridge.LyricFormatDto.plain => LyricFormat.plain,
  },
  offsetMs: value.offsetMs,
  lines: value.lines
      .map(
        (line) => LyricLine(
          startMs: line.startMs,
          durationMs: line.durationMs,
          text: line.text,
          translation: line.translation,
          transliteration: line.transliteration,
          words: line.words
              .map(
                (word) => LyricWord(
                  startMs: word.startMs,
                  durationMs: word.durationMs,
                  text: word.text,
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false),
);

Playlist _playlist(bridge.CloudPlaylistDto value) => Playlist(
  listId: value.listId,
  globalCollectionId: value.globalCollectionId,
  name: value.name,
  intro: value.intro,
  artworkUrl: value.artworkUrl,
  count: value.count ?? 0,
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

RecommendationBatch _recommendationBatch(bridge.RecommendationBatchDto value) =>
    RecommendationBatch(
      title: value.title,
      subtitle: value.subtitle,
      markList: value.markList,
      mark: value.mark,
      songs: value.songs.map(_songFromDto).toList(growable: false),
    );

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
  const DeniedResolution();
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
