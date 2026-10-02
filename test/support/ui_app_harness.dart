import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/app_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/logging/app_logging_controller.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/discovery_card.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/search_page.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/features/home/home_discovery.dart';

import 'player_ui_harness.dart';

/// Real app routes and screens with in-memory data; shared by behavioral tests
/// and the explicitly invoked visual review tool. No native runtime or network.
class UiAppHarness {
  UiAppHarness._(this.handler, this.settings, this.playlists) {
    router = createAppRouter(auth);
  }

  final PlayerUiHandler handler;
  final AppSettingsController settings;
  final List<Playlist> playlists;
  final auth = UiAuthController();
  late final GoRouter router;

  static Future<UiAppHarness> create({
    List<Song>? songs,
    List<Playlist> playlists = const [],
  }) async => UiAppHarness._(
    PlayerUiHandler(songs: songs),
    await AppSettingsController.create(_MemoryPreferences()),
    playlists,
  );

  Widget app({
    double textScale = 1,
    bool reduceMotion = true,
    ThemeData? theme,
    Widget Function(BuildContext, Widget)? builder,
  }) => ProviderScope(
    overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      authControllerProvider.overrideWith((ref) => auth),
      appSettingsControllerProvider.overrideWith((ref) => settings),
      appLoggingControllerProvider.overrideWith((ref) => _UiLogging()),
      audioCacheProvider.overrideWithValue(_UiCache()),
      musicRepositoryProvider.overrideWithValue(
        _UiMusic(handler.songs, playlists),
      ),
      libraryRepositoryProvider.overrideWithValue(_UiLibrary(handler.songs)),
      libraryReadyProvider.overrideWithValue(true),
      songIsFavoriteProvider.overrideWith((ref, id) => const AsyncData(false)),
      lyricsRepositoryProvider.overrideWithValue(UiLyricsRepository()),
      dailyRecommendationsProvider.overrideWith(
        (ref) => Stream.value(handler.songs),
      ),
      homeDiscoveryCardProvider.overrideWith(
        (ref, id) => Stream.value(
          DiscoveryCard(
            id: id,
            title: id == 3001 ? '为你精选' : '继续发现',
            songs: handler.songs,
          ),
        ),
      ),
      historyEntriesProvider.overrideWith(
        (ref) => Stream.value([
          for (final song in handler.songs.take(4))
            HistoryEntry(song: song, playedAt: DateTime(2026), playCount: 1),
        ]),
      ),
      favoriteSongsProvider.overrideWith((ref) => Stream.value(handler.songs)),
      libraryPlaylistsProvider.overrideWith((ref) => Stream.value(playlists)),
      libraryPlaylistTracksProvider.overrideWith(
        (ref, id) => Stream.value(handler.songs),
      ),
      librarySyncStatusProvider.overrideWith(
        (ref) => Stream.value(const LibrarySyncStatus.idle()),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(const UserProfile(displayName: '听风', userId: 1)),
      ),
      userVipProvider.overrideWith((ref) => Stream.value(const UserVip())),
    ],
    child: MaterialApp.router(
      theme: theme ?? buildKgTheme(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: builder?.call(context, child!) ?? child!,
      ),
    ),
  );

  Future<void> dispose() async {
    router.dispose();
    await handler.close();
  }
}

class UiAuthController extends ChangeNotifier implements AuthController {
  @override
  AuthStatus status = AuthStatus.authenticated;
  @override
  String? message;
  @override
  int resendSeconds = 0;
  @override
  bool get authenticated => status == AuthStatus.authenticated;
  @override
  bool get busy => false;
  @override
  bool get registeringDevice => false;
  @override
  AuthSnapshot get snapshot => AuthSnapshot(
    authenticated: authenticated,
    fingerprintRegistered: true,
    userId: 1,
  );

  void expire() {
    status = AuthStatus.expired;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryPreferences implements PreferenceStore {
  final _values = <String, Object>{};
  @override
  Future<T> read<T>(PreferenceKey<T> key) async =>
      key.decode(_values[key.name]) ?? key.defaultValue;
  @override
  Future<void> write<T>(PreferenceKey<T> key, T value) async =>
      _values[key.name] = key.encode(value);
}

class _UiCache extends Fake implements AudioCacheManager {
  @override
  Future<AudioCacheUsage> usage() async => const AudioCacheUsage(
    totalBytes: 128 * 1024 * 1024,
    maxBytes: AudioCacheLimits.defaultBytes,
  );
}

class _UiMusic extends Fake implements MusicRepository {
  _UiMusic(this.songs, this.playlists);
  final List<Playlist> playlists;
  final List<Song> songs;

  @override
  Stream<SearchPage> search(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => Stream.value(
    SearchPage(
      songs: songs,
      page: page,
      pageSize: pageSize,
      total: songs.length,
    ),
  );

  @override
  Stream<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => Stream.value(
    PlaylistSearchPage(
      items: [
        for (final playlist in playlists)
          PlaylistSearchHit(
            name: playlist.name,
            globalCollectionId: playlist.globalCollectionId ?? playlist.localId,
            artworkUrl: playlist.artworkUrl,
            creatorName: playlist.creatorName,
            songCount: playlist.count,
          ),
      ],
      page: page,
      pageSize: pageSize,
      total: playlists.length,
    ),
  );

  @override
  Stream<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int? userId,
    int page = 1,
    int pageSize = 50,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => Stream.value(
    SearchPage(
      songs: songs,
      page: page,
      pageSize: pageSize,
      total: songs.length,
    ),
  );
}

class _UiLibrary extends Fake implements LibraryRepository {
  _UiLibrary(this.songs);
  final List<Song> songs;
  @override
  Stream<SearchPage> loadPlaylistPage(
    String localId, {
    int page = 1,
    int pageSize = 100,
    bool forceRefresh = false,
  }) => Stream.value(
    SearchPage(
      songs: songs,
      page: page,
      pageSize: pageSize,
      total: songs.length,
    ),
  );
}

class _UiLogging extends ChangeNotifier implements AppLoggingController {
  @override
  AppLogLevel get level => AppLogLevel.info;
  @override
  bool get nativeAvailable => true;
  @override
  String? get nativeError => null;
  @override
  Future<({List<AppLogEntry> entries, int totalBytes})> loadSnapshot({
    int limit = 1000,
  }) async => (entries: const <AppLogEntry>[], totalBytes: 0);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
