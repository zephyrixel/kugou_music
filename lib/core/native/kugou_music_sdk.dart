import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/discovery_card.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';
import 'package:kgmusic/core/native/secure_session_store.dart';
import 'package:kgmusic/core/native/rust_bridge.dart' as bridge;
import 'package:kgmusic/core/platform/device_profile.dart';

import 'package:kgmusic/core/auth/account_session.dart';
import 'package:kgmusic/core/native/music_sdk_contract.dart';
import 'package:kgmusic/core/models/playback.dart';
import 'package:kgmusic/core/models/search_page.dart';
import 'package:kgmusic/core/models/music_sdk_exception.dart';

class KugouMusicSdk implements MusicSdk, LyricsSdk {
  KugouMusicSdk(
    FlutterSecureStorage storage, {
    DeviceProfileSource? deviceProfiles,
    AccountSession? accountSession,
    this.onSessionPersistenceFailure,
  }) : accountSession = accountSession ?? AccountSession(),
       _storage = storage,
       _deviceProfiles = deviceProfiles ?? AndroidDeviceProfileSource(storage),
       _sessions = SecureSessionStore(storage, key: sessionKey);

  static const sessionKey = AuthStorageKeys.sessionV2;
  static const legacySessionKey = AuthStorageKeys.legacySessionV1;
  final FlutterSecureStorage _storage;
  final AccountSession accountSession;
  final void Function()? onSessionPersistenceFailure;
  bool _closed = false;
  final Set<Future<void>> _inFlight = {};

  Future<void> close() async {
    _closed = true;
    accountSession.invalidate();
    await Future.wait(_inFlight.toList());
  }

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
    accountSession.update(_auth(await bridge.getAuthState()));
    await _persistSession(accountSession.generation);
  }

  @override
  Future<AuthSnapshot> authState() async => accountSession.snapshot;

  @override
  Future<void> sendSmsCode(String mobile) async {
    await ensureDeviceRegistered();
    await _guard(() => bridge.sendSmsCode(mobile: mobile));
  }

  @override
  Future<AuthSnapshot> loginBySms(String mobile, String code) => _guard(
    () async => _auth(await bridge.loginBySms(mobile: mobile, code: code)),
    criticalSessionWrite: true,
  );

  @override
  Future<AuthSnapshot> refreshLogin() => _guard(
    () async => _auth(await bridge.refreshLogin()),
    criticalSessionWrite: true,
  );

  @override
  Future<AuthSnapshot> ensureDeviceRegistered() =>
      _guard(() async => _auth(await bridge.ensureDeviceRegistered()));

  @override
  Future<AuthSnapshot> registerDevice() =>
      _guard(() async => _auth(await bridge.registerDevice()));

  @override
  Future<void> logout() async {
    try {
      await bridge.logout();
    } finally {
      await _sessions.delete();
    }
  }

  @override
  Future<List<Song>> everydayRecommendations() => _guard(() async {
    final result = await bridge.getEverydayRecommendations();
    return result.map(_songFromDto).toList(growable: false);
  });

  @override
  Future<DiscoveryCard> discoveryCard(int cardId, {int pageSize = 10}) =>
      _guard(() async {
        final value = await bridge.getDiscoveryCard(
          cardId: cardId,
          pageSize: pageSize,
        );
        final title = value.title?.trim();
        final subtitle = value.subtitle?.trim();
        return DiscoveryCard(
          id: value.cardId,
          title: title?.isNotEmpty == true ? title! : '为你发现',
          subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
          songs: value.songs.map(_songFromDto).toList(growable: false),
        );
      });

  @override
  Future<RecommendationBatch> personalFm(PersonalFmInput input) =>
      _guard(() async {
        final value = await bridge.getPersonalFm(
          request: bridge.PersonalFmRequestDto(
            action: switch (input.action) {
              PersonalFmAction.play => bridge.PersonalFmActionDto.play,
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
    List<RecommendationProfileItem> items, {
    required bool complete,
    required int previousSyncPoint,
    required int nextSyncPoint,
    String? lastUploadHash,
  }) => _guard(() async {
    final value = await bridge.reportRecommendationHistory(
      items: items
          .map(
            (item) => bridge.RecommendationProfileItemDto(
              action: switch (item.action) {
                RecommendationProfileAction.collect =>
                  bridge.RecommendationProfileActionDto.collect,
                RecommendationProfileAction.playComplete =>
                  bridge.RecommendationProfileActionDto.playComplete,
                RecommendationProfileAction.playShort =>
                  bridge.RecommendationProfileActionDto.playShort,
                RecommendationProfileAction.trash =>
                  bridge.RecommendationProfileActionDto.trash,
              },
              standardHash: item.standardHash,
              mixSongId: item.mixSongId,
              eventTimeMs: item.eventTimeMs,
              count: item.count,
              flagBits: item.flagBits,
              sourceBits: item.sourceBits,
            ),
          )
          .toList(growable: false),
      previousSyncPoint: previousSyncPoint,
      nextSyncPoint: nextSyncPoint,
      complete: complete,
      lastUploadHash: lastUploadHash,
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
  });

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
      });

  @override
  Future<void> deletePlaylist({required int listId, required bool collected}) =>
      _guard(
        () => bridge.deleteCloudPlaylist(listId: listId, collected: collected),
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
  );

  @override
  Future<PlaylistTracksMutation> addSongToPlaylist(int listId, Song song) =>
      _guard(() async {
        final value = await bridge.addSongToPlaylist(
          listId: listId,
          song: _songToDto(song),
        );
        return PlaylistTracksMutation(fileIds: value.fileIds);
      });

  @override
  Future<void> removeSongFromPlaylist(int listId, int fileId) => _guard(
    () => bridge.removeSongFromPlaylist(listId: listId, fileId: fileId),
  );

  Future<T> _guard<T>(
    Future<T> Function() action, {
    bool criticalSessionWrite = false,
  }) {
    if (_closed) return Future.error(const StaleSessionException());
    final result = _execute(action, criticalSessionWrite: criticalSessionWrite);
    late final Future<void> settled;
    settled = result
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() => _inFlight.remove(settled));
    _inFlight.add(settled);
    return result;
  }

  Future<T> _execute<T>(
    Future<T> Function() action, {
    bool criticalSessionWrite = false,
  }) async {
    final generation = accountSession.generation;
    try {
      final value = await action();
      if (!accountSession.isCurrent(generation)) {
        throw const StaleSessionException();
      }
      try {
        await _persistSession(generation);
      } catch (error) {
        AppLog.warn('安全保存登录信息失败', target: 'native.session', error: error);
        if (criticalSessionWrite) rethrow;
        onSessionPersistenceFailure?.call();
      }
      if (!accountSession.isCurrent(generation)) {
        throw const StaleSessionException();
      }
      return value;
    } on bridge.BridgeError catch (error, stackTrace) {
      if (!accountSession.isCurrent(generation)) {
        throw const StaleSessionException();
      }
      _logBridgeError(error, stackTrace);
      final exception = MusicSdkException(
        error.message,
        retryable: error.retryable,
        expired: error.kind == bridge.BridgeErrorKind.authenticationExpired,
        authenticationRequired:
            error.kind == bridge.BridgeErrorKind.authenticationRequired,
        code: error.code,
      );
      if (exception.expired || exception.authenticationRequired) {
        accountSession.expire();
      } else {
        try {
          await _persistSession(generation);
        } catch (_) {
          /* Preserve the original SDK error. */
        }
      }
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  Future<void> _persistSession(int generation) async {
    final value = await bridge.exportSession();
    await _sessions.writeIfChanged(
      value,
      isCurrent: () => accountSession.isCurrent(generation),
    );
  }
}

void _logBridgeError(bridge.BridgeError error, StackTrace stackTrace) {
  final message =
      'Rust bridge 调用失败 kind=${error.kind.name} code=${error.code ?? '-'} retryable=${error.retryable}';
  switch (error.kind) {
    case bridge.BridgeErrorKind.transport:
    case bridge.BridgeErrorKind.internal:
      AppLog.error(
        message,
        target: 'native.sdk',
        error: error.message,
        stackTrace: stackTrace,
      );
      return;
    case bridge.BridgeErrorKind.invalidArgument:
    case bridge.BridgeErrorKind.sessionInvalid:
    case bridge.BridgeErrorKind.upstream:
    case bridge.BridgeErrorKind.authenticationRequired:
    case bridge.BridgeErrorKind.authenticationExpired:
    case bridge.BridgeErrorKind.securityChallenge:
    case bridge.BridgeErrorKind.unsupported:
      AppLog.warn(message, target: 'native.sdk', error: error.message);
      return;
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
  collectTimeSecs: value.collectTimeSecs,
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
  collectTimeSecs: value.collectTimeSecs,
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
  createdAt: _epochSecondsToDate(value.createTime),
  updatedAt: _epochSecondsToDate(value.updateTime),
  remoteSort: value.sort,
);

/// Wire timestamps are Unix seconds; `0` means "not supplied".
DateTime? _epochSecondsToDate(int? seconds) => seconds == null || seconds <= 0
    ? null
    : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

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
      syncNeed: value.syncNeed,
      syncPoint: value.syncPoint,
      songs: value.songs.map(_songFromDto).toList(growable: false),
    );
