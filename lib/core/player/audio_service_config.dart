import 'package:audio_service/audio_service.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

const kgMusicAudioServiceConfig = AudioServiceConfig(
  androidNotificationChannelId: 'com.zephyrixel.kgmusic.playback',
  androidNotificationChannelName: 'KGMusic 播放',
  androidNotificationChannelDescription: '显示当前歌曲并提供后台播放控制',
  notificationColor: KgColors.accent,
  androidNotificationIcon: 'drawable/ic_stat_kgmusic',
  androidShowNotificationBadge: false,
  androidNotificationClickStartsActivity: true,
  androidNotificationOngoing: false,
  androidStopForegroundOnPause: false,
  artDownscaleWidth: 512,
  artDownscaleHeight: 512,
  fastForwardInterval: Duration(seconds: 10),
  rewindInterval: Duration(seconds: 10),
  preloadArtwork: false,
);
