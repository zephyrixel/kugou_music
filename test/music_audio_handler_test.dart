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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}

MusicAudioHandler _handler(
  _FakePlayerSdk sdk,
  _FakeAudioPlayer player,
  List<Song> history,
) => MusicAudioHandler(
  sdk,
  (song) async => history.add(song),
  _FakeAudioCache(),
  player: player,
  configureSession: () async {},
  observeLifecycle: false,
  restoreQueueOnStart: false,
);

class _FakePlayerSdk implements PlayerSdk {
  bool controlled = false;
  final Map<String, Completer<PlaybackResolution>> _resolutions = {};

  void complete(Song song, AudioQuality quality) {
    _resolutions.remove(song.id)!.complete(_resolution(song, quality));
  }

  @override
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  }) {
    if (!controlled) return Future.value(_resolution(song, quality));
    return (_resolutions[song.id] ??= Completer()).future;
  }

  PlayableResolution _resolution(Song song, AudioQuality quality) =>
      PlayableResolution(
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
  Future<SmsLoginResult> loginBySms(String mobile, String code) async =>
      SmsLoginResult(auth: await authState());
  @override
  Future<AuthSnapshot> refreshLogin() => authState();
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
