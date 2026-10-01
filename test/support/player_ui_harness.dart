import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/lyrics_repository.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/playback.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

/// In-memory UI port. No native engine, account, or network is involved.
class PlayerUiHandler extends BaseAudioHandler implements MusicAudioHandler {
  PlayerUiHandler({List<Song>? songs})
    : songs =
          songs ??
          const [
            Song(
              id: 'demo',
              title: '测试歌曲',
              artist: '测试歌手',
              hashes: AudioHashes(standard: 'hash'),
            ),
          ] {
    final song = this.songs.first;
    mediaItem.add(
      MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artistLabel,
        artUri: song.artworkUrl == null ? null : Uri.parse(song.artworkUrl!),
        duration: const Duration(minutes: 4),
      ),
    );
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready),
    );
  }

  @override
  final List<Song> songs;
  @override
  int get currentIndex => 0;
  @override
  bool get isRecommendationQueue => false;
  @override
  Duration get position => const Duration(seconds: 38);
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream =>
      Stream.value(const Duration(minutes: 4));
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<String?> get messages => const Stream.empty();
  @override
  PlaybackQualityState get qualityState =>
      const PlaybackQualityState(requested: AudioQuality.standard);
  @override
  Stream<PlaybackQualityState> get qualityStateStream => const Stream.empty();
  @override
  PlaybackQueueState get queueState => PlaybackQueueState(
    origin: const PlaybackQueueOrigin(
      kind: PlaybackQueueOriginKind.dailyRecommendations,
      title: '每日推荐',
    ),
    songs: songs,
    currentIndex: 0,
    order: PlaybackOrder.sequential,
    hasMore: false,
  );
  @override
  Stream<PlaybackQueueState?> get queueStateStream => const Stream.empty();

  Duration? lastSeek;
  int playCalls = 0;
  @override
  Future<void> play() async {
    playCalls++;
    playbackState.add(playbackState.value.copyWith(playing: true));
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(playing: false));
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  Future<void> close() async {
    await mediaItem.close();
    await playbackState.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UiLyricsRepository extends Fake implements LyricsRepository {
  @override
  Future<LyricDocument?> load(Song song, {bool forceRefresh = false}) async =>
      LyricDocument(
        format: LyricFormat.lrc,
        offsetMs: 0,
        lines: List.generate(
          20,
          (index) => LyricLine(
            startMs: index * 1000,
            durationMs: 1000,
            text: '歌词第 $index 行',
          ),
        ),
      );
}

Widget playerUiScope({
  required PlayerUiHandler handler,
  required Widget child,
}) => ProviderScope(
  overrides: [
    audioHandlerProvider.overrideWithValue(handler),
    libraryReadyProvider.overrideWithValue(false),
    songIsFavoriteProvider.overrideWith((ref, id) => const AsyncData(false)),
    lyricsRepositoryProvider.overrideWithValue(UiLyricsRepository()),
  ],
  child: child,
);

Widget playerUiApp({
  required PlayerUiHandler handler,
  required Widget home,
  bool reduceMotion = false,
  double textScale = 1,
}) => playerUiScope(
  handler: handler,
  child: MaterialApp(
    theme: buildKgTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  ),
);
