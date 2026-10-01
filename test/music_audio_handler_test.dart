// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/audio_player_port.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('late song preparation preserves queue appends and edits', () async {
    final sdk = _FakePlayerSdk();
    final player = _FakeAudioPlayer();
    final handler = _handler(sdk, player, []);
    final source = _QueueSource();
    final request = PlaybackQueueRequest(
      origin: const PlaybackQueueOrigin(
        kind: PlaybackQueueOriginKind.search,
        title: 'Search',
      ),
      songs: const [songA, songB],
      source: source,
      hasMore: true,
      nextPage: 2,
      pageSize: 2,
    );
    await handler.playSong(songA, queueRequest: request);
    sdk.controlled = true;
    final switching = handler.skipToQueueItem(1);
    await Future<void>.delayed(Duration.zero);
    await handler.moveQueueItem(1, 0);
    await handler.loadMoreQueue();
    sdk.complete(songB, AudioQuality.standard);
    await switching;
    expect(handler.songs.map((song) => song.id), ['b', 'a', 'c']);
    expect(handler.currentIndex, 0);
    await handler.dispose();
    await player.close();
  });

  test('failed end-of-queue prefetch stops until an explicit retry', () async {
    final player = _FakeAudioPlayer();
    final handler = _handler(_FakePlayerSdk(), player, []);
    final source = _QueueSource()..failure = true;
    await handler.playSong(
      songA,
      queueRequest: PlaybackQueueRequest(
        origin: const PlaybackQueueOrigin(
          kind: PlaybackQueueOriginKind.search,
          title: 'Search',
        ),
        songs: const [songA],
        source: source,
        nextPage: 2,
        hasMore: true,
        pageSize: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(source.calls, 1);
    expect(handler.queueState?.error, isNotNull);
    source.failure = false;
    await handler.loadMoreQueue();
    expect(source.calls, 2);
    expect(handler.queueState?.error, isNull);
    await handler.dispose();
    await player.close();
  });

  test(
    'clearing a queue publishes an empty state to existing listeners',
    () async {
      final player = _FakeAudioPlayer();
      final handler = _handler(_FakePlayerSdk(), player, []);
      await handler.playSong(songA);
      final empty = handler.queueStateStream.firstWhere(
        (state) => state == null,
      );
      await handler.clearQueue();
      expect(await empty, isNull);
      expect(handler.songs, isEmpty);
      await handler.dispose();
      await player.close();
    },
  );

  test(
    'preview bounds apply again after replay and clamp system seeks',
    () async {
      final sdk = _FakePlayerSdk()..preview = true;
      final player = _FakeAudioPlayer();
      final handler = _handler(sdk, player, []);
      await handler.playSong(songA);
      player.emitPosition(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(player.playing, isFalse);
      await handler.play();
      expect(player.position, Duration.zero);
      expect(player.playing, isTrue);
      player.emitPosition(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(player.playing, isFalse);
      await handler.seek(const Duration(seconds: 20));
      expect(player.position, const Duration(seconds: 1));
      expect(player.playing, isFalse);
      await handler.dispose();
      await player.close();
    },
  );

  test('stale playback preparation cannot replace a newer song', () async {
    final sdk = _FakePlayerSdk()..controlled = true;
    final player = _FakeAudioPlayer();
    final history = <Song>[];
    final handler = _handler(sdk, player, history);

    final first = handler.playSong(songA, queueSongs: const [songA, songB]);
    final second = handler.playSong(songB, queueSongs: const [songA, songB]);
    await Future<void>.delayed(Duration.zero);

    sdk.complete(songB, AudioQuality.standard);
    await second;
    sdk.complete(songA, AudioQuality.standard);
    await first;

    expect(handler.currentIndex, 1);
    expect(handler.songs[handler.currentIndex], songB);
    expect(player.initialPositions, [Duration.zero]);
    expect(history, [songB]);
    await player.close();
  });

  test(
    'quality switching keeps position and does not duplicate history',
    () async {
      final sdk = _FakePlayerSdk();
      final player = _FakeAudioPlayer();
      final history = <Song>[];
      final handler = _handler(sdk, player, history);

      await handler.playSong(songA);
      player.positionValue = const Duration(seconds: 31);
      await handler.setPlaybackQuality(AudioQuality.high);

      expect(player.initialPositions, [
        Duration.zero,
        const Duration(seconds: 31),
      ]);
      expect(player.playing, isTrue);
      expect(history, [songA]);
      expect(handler.qualityState.actual, AudioQuality.high);
      await player.close();
    },
  );

  test('restored default quality is used for the first playback', () async {
    final sdk = _FakePlayerSdk();
    final player = _FakeAudioPlayer();
    final history = <Song>[];
    final handler = _handler(
      sdk,
      player,
      history,
      initialQuality: AudioQuality.flac,
    );

    await handler.playSong(songA);

    expect(sdk.requestedQualities, [AudioQuality.flac]);
    expect(handler.qualityState.requested, AudioQuality.flac);
    await player.close();
  });

  test('dispose releases the player exactly once', () async {
    final player = _FakeAudioPlayer();
    final handler = _handler(_FakePlayerSdk(), player, <Song>[]);

    await handler.dispose();
    await handler.dispose();

    expect(player.disposeCount, 1);
    await player.close();
  });

  test('failed quality switch restores the persisted preference', () async {
    final sdk = _FakePlayerSdk();
    final player = _FakeAudioPlayer();
    final history = <Song>[];
    final persisted = <AudioQuality>[];
    final handler = _handler(
      sdk,
      player,
      history,
      persistPreferredQuality: (quality) async => persisted.add(quality),
    );
    await handler.playSong(songA);
    sdk.unavailable = true;

    await expectLater(
      handler.setPlaybackQuality(AudioQuality.high),
      throwsA(isA<MusicSdkException>()),
    );

    expect(persisted, [AudioQuality.high, AudioQuality.standard]);
    expect(handler.qualityState.requested, AudioQuality.standard);
    expect(handler.qualityState.actual, AudioQuality.standard);
    await player.close();
  });

  test('completed audio advances to the next queue item', () async {
    final sdk = _FakePlayerSdk();
    final player = _FakeAudioPlayer();
    final history = <Song>[];
    final handler = _handler(sdk, player, history);

    await handler.playSong(songA, queueSongs: const [songA, songB]);
    player.emitCompleted();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(handler.currentIndex, 1);
    expect(handler.songs[handler.currentIndex], songB);
    expect(history, [songA, songB]);
    await player.close();
  });

  test('推荐画像会话跨音质切换保留并在换歌时结束', () async {
    final sdk = _FakePlayerSdk();
    final player = _FakeAudioPlayer();
    final history = <Song>[];
    final recommendation = <Song>[];
    final handler = _handler(
      sdk,
      player,
      history,
      recommendation: recommendation,
    );

    await handler.playSong(songA);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await handler.setPlaybackQuality(AudioQuality.high);
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await handler.playSong(songB, queueSongs: const [songA, songB]);

    expect(history, [songA, songB]);
    expect(recommendation, [songA]);
    await player.close();
  });
}

MusicAudioHandler _handler(
  _FakePlayerSdk sdk,
  _FakeAudioPlayer player,
  List<Song> history, {
  List<Song>? recommendation,
  AudioQuality initialQuality = AudioQuality.standard,
  Future<void> Function(AudioQuality)? persistPreferredQuality,
}) => MusicAudioHandler(
  sdk,
  (song) async => history.add(song),
  _FakeAudioCache(),
  recordRecommendationPlayback:
      (song, {required listened, required sourceBits}) async =>
          recommendation?.add(song),
  player: player,
  configureSession: () async {},
  initialQuality: initialQuality,
  persistPreferredQuality: persistPreferredQuality,
  observeLifecycle: false,
  restoreQueueOnStart: false,
);

class _FakePlayerSdk implements PlayerSdk {
  bool controlled = false;
  bool unavailable = false;
  bool preview = false;
  final Map<String, Completer<PlaybackResolution>> _resolutions = {};
  final List<AudioQuality> requestedQualities = [];

  void complete(Song song, AudioQuality quality) {
    _resolutions.remove(song.id)!.complete(_resolution(song, quality));
  }

  @override
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  }) {
    requestedQualities.add(quality);
    if (unavailable) return Future.value(const UnavailableResolution());
    if (!controlled) return Future.value(_resolution(song, quality));
    return (_resolutions[song.id] ??= Completer()).future;
  }

  PlayableResolution _resolution(Song song, AudioQuality quality) => preview
      ? PreviewResolution(
          url: 'https://audio.example/${song.id}.mp3',
          quality: quality,
          endMs: 1000,
        )
      : PlayableResolution(
          url: 'https://audio.example/${song.id}/${quality.name}.mp3',
          quality: quality,
          durationSecs: 180,
        );

  @override
  Future<void> initialize() async {}
  @override
  Future<AuthSnapshot> authState() async => const AuthSnapshot(
    authenticated: true,
    userId: 1,
    fingerprintRegistered: true,
  );
  @override
  Future<void> sendSmsCode(String mobile) async {}
  @override
  Future<AuthSnapshot> loginBySms(String mobile, String code) => authState();
  @override
  Future<AuthSnapshot> refreshLogin() => authState();
  @override
  Future<AuthSnapshot> ensureDeviceRegistered() => authState();
  @override
  Future<AuthSnapshot> registerDevice() => authState();
  @override
  Future<void> logout() async {}
}

class _FakeAudioCache implements AudioCache {
  CachedAudioHandle? active;

  @override
  Future<CachedAudioHandle> sourceFor(
    Song song,
    PlayableResolution resolution,
  ) async => CachedAudioHandle(
    source: LockCachingAudioSource(
      Uri.parse(resolution.url),
      cacheFile: File('${Directory.systemTemp.path}/${song.id}.mp3'),
    ),
    file: File('${Directory.systemTemp.path}/${song.id}.mp3'),
  );

  @override
  void setActive(CachedAudioHandle? handle) => active = handle;
}

class _FakeAudioPlayer implements AudioPlayerPort {
  final _events = StreamController<PlaybackEvent>.broadcast();
  final _processing = StreamController<ProcessingState>.broadcast();
  final _positions = StreamController<Duration>.broadcast();
  final _durations = StreamController<Duration?>.broadcast();
  final _buffered = StreamController<Duration>.broadcast();

  final List<Duration?> initialPositions = [];
  PlaybackEvent _event = PlaybackEvent();
  ProcessingState _state = ProcessingState.idle;
  bool _playing = false;
  Duration positionValue = Duration.zero;
  int disposeCount = 0;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<ProcessingState> get processingStateStream => _processing.stream;
  @override
  Stream<Duration> get positionStream => _positions.stream;
  @override
  Stream<Duration?> get durationStream => _durations.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _buffered.stream;
  @override
  PlaybackEvent get playbackEvent => _event;
  @override
  ProcessingState get processingState => _state;
  @override
  bool get playing => _playing;
  @override
  Duration get position => positionValue;
  @override
  double get speed => 1;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    Duration? initialPosition,
  }) async {
    initialPositions.add(initialPosition);
    positionValue = initialPosition ?? Duration.zero;
    _emit(ProcessingState.ready);
    const duration = Duration(minutes: 3);
    _durations.add(duration);
    return duration;
  }

  @override
  Future<void> play() async {
    _playing = true;
    _emit(_state);
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _emit(_state);
  }

  @override
  Future<void> seek(Duration position) async {
    positionValue = position;
    _positions.add(position);
    _emit(_state);
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _emit(ProcessingState.idle);
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  void emitPosition(Duration position) {
    positionValue = position;
    _positions.add(position);
  }

  void emitCompleted() => _emit(ProcessingState.completed);

  void _emit(ProcessingState state) {
    _state = state;
    _event = PlaybackEvent(
      processingState: state,
      updatePosition: positionValue,
      duration: const Duration(minutes: 3),
    );
    _processing.add(state);
    _events.add(_event);
  }

  Future<void> close() async {
    await Future.wait([
      _events.close(),
      _processing.close(),
      _positions.close(),
      _durations.close(),
      _buffered.close(),
    ]);
  }
}

const songA = Song(
  id: 'a',
  title: 'A',
  hashes: AudioHashes(standard: 'a', high: 'a-high'),
);
const songB = Song(
  id: 'b',
  title: 'B',
  hashes: AudioHashes(standard: 'b', high: 'b-high'),
);

class _QueueSource implements PlaybackQueueSource {
  int calls = 0;
  bool failure = false;
  @override
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request) async {
    calls++;
    if (failure) throw StateError('offline');
    return PlaybackQueuePage(
      page: request.page,
      pageSize: request.songs.length,
      songs: const [
        Song(
          id: 'c',
          title: 'C',
          hashes: AudioHashes(standard: 'c'),
        ),
      ],
      hasMore: false,
    );
  }
}
