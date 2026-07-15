import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/audio_service_config.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/system_media_projection.dart';

void main() {
  group('SystemMediaProjection', () {
    test('publishes standard Android controls and seek capabilities', () {
      final state = SystemMediaProjection.playbackState(
        event: PlaybackEvent(
          processingState: ProcessingState.ready,
          updatePosition: const Duration(seconds: 12),
          bufferedPosition: const Duration(seconds: 24),
        ),
        playing: true,
        order: PlaybackOrder.repeatAll,
        currentIndex: 3,
        speed: 1,
      );

      expect(state.controls.map((control) => control.action), [
        MediaAction.skipToPrevious,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.stop,
      ]);
      expect(state.androidCompactActionIndices, [0, 1, 2]);
      expect(
        state.systemActions,
        containsAll({
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        }),
      );
      expect(state.processingState, AudioProcessingState.ready);
      expect(state.repeatMode, AudioServiceRepeatMode.all);
      expect(state.shuffleMode, AudioServiceShuffleMode.none);
      expect(state.queueIndex, 3);
      expect(state.updatePosition, const Duration(seconds: 12));
    });

    test('maps player errors into the system media session', () {
      final state = SystemMediaProjection.playbackState(
        event: PlaybackEvent(
          processingState: ProcessingState.loading,
          errorCode: 500,
          errorMessage: 'load failed',
        ),
        playing: false,
        order: PlaybackOrder.sequential,
        currentIndex: -1,
        speed: 1,
      );

      expect(state.processingState, AudioProcessingState.error);
      expect(state.errorCode, 500);
      expect(state.errorMessage, 'load failed');
      expect(state.queueIndex, isNull);
      expect(state.controls[1].action, MediaAction.playPause);
      expect(
        state.controls[1].androidIcon,
        'drawable/audio_service_play_arrow',
      );
    });

    test(
      'uses the loaded duration and normalized artwork for media metadata',
      () {
        const song = Song(
          id: 'song-1',
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationSecs: 120,
          artworkUrl: '//imge.kugou.com/stdmusic/{size}/cover.jpg',
          hashes: AudioHashes(standard: 'hash'),
        );

        final item = SystemMediaProjection.mediaItemForSong(
          song,
          actualDuration: const Duration(milliseconds: 121234),
        );

        expect(item.duration, const Duration(milliseconds: 121234));
        expect(item.artUri?.scheme, 'https');
        expect(item.artUri.toString(), contains('/480/'));
        expect(item.displayTitle, 'Song');
        expect(item.displaySubtitle, 'Artist');
      },
    );

    test('system repeat and shuffle commands preserve unrelated modes', () {
      expect(
        SystemMediaProjection.applyRepeatMode(
          PlaybackOrder.shuffle,
          AudioServiceRepeatMode.none,
        ),
        PlaybackOrder.shuffle,
      );
      expect(
        SystemMediaProjection.applyShuffleMode(
          PlaybackOrder.repeatOne,
          AudioServiceShuffleMode.none,
        ),
        PlaybackOrder.repeatOne,
      );
      expect(
        SystemMediaProjection.applyRepeatMode(
          PlaybackOrder.repeatAll,
          AudioServiceRepeatMode.none,
        ),
        PlaybackOrder.sequential,
      );
      expect(
        SystemMediaProjection.applyShuffleMode(
          PlaybackOrder.sequential,
          AudioServiceShuffleMode.all,
        ),
        PlaybackOrder.shuffle,
      );
    });
  });

  test('audio service config keeps paused external controls available', () {
    expect(kgMusicAudioServiceConfig.androidStopForegroundOnPause, isFalse);
    expect(
      kgMusicAudioServiceConfig.androidNotificationIcon,
      'drawable/ic_stat_kgmusic',
    );
    expect(kgMusicAudioServiceConfig.preloadArtwork, isFalse);
    expect(kgMusicAudioServiceConfig.artDownscaleWidth, 512);
    expect(kgMusicAudioServiceConfig.artDownscaleHeight, 512);
  });
}
