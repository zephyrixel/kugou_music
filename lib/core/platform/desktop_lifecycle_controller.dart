import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/platform/desktop_window_geometry.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

typedef DesktopShutdown = Future<void> Function();

class DesktopLifecycleController with WindowListener, TrayListener {
  DesktopLifecycleController({
    required this.audioHandler,
    required this.preferences,
    required this.shutdown,
    required this.finalizeShutdown,
  });

  static bool get isSupported => Platform.isLinux || Platform.isWindows;

  static final _widthKey = _doubleKey('desktop_window_width', 1180);
  static final _heightKey = _doubleKey('desktop_window_height', 760);
  static final _xKey = _doubleKey('desktop_window_x', double.nan);
  static final _yKey = _doubleKey('desktop_window_y', double.nan);
  static final _maximizedKey = PreferenceKey<bool>(
    name: 'desktop_window_maximized',
    defaultValue: false,
    decode: (value) => value is bool ? value : null,
    encode: (value) => value,
  );

  final AudioHandler audioHandler;
  final PreferenceStore preferences;
  final DesktopShutdown shutdown;
  final DesktopShutdown finalizeShutdown;
  StreamSubscription<bool>? _playbackSubscription;
  Timer? _geometryTimer;
  bool _quitting = false;
  bool _maximized = false;
  bool _listenersRegistered = false;
  bool _preventClose = false;

  Future<void> initialize() async {
    if (!isSupported) return;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _listenersRegistered = true;

    final width = (await preferences.read(
      _widthKey,
    )).clamp(720, 4096).toDouble();
    final height = (await preferences.read(
      _heightKey,
    )).clamp(560, 2160).toDouble();
    final x = await preferences.read(_xKey);
    final y = await preferences.read(_yKey);
    final restorePosition = await _canRestorePosition(
      Rect.fromLTWH(x, y, width, height),
    );
    _maximized = await preferences.read(_maximizedKey);
    await windowManager.setPreventClose(true);
    _preventClose = true;
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: Size(width, height),
        minimumSize: const Size(720, 560),
        center: !restorePosition,
        title: 'KGMusic',
        backgroundColor: const Color(0xFF020719),
      ),
      () async {
        if (restorePosition) {
          await windowManager.setPosition(Offset(x, y));
        }
        if (_maximized) await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
      },
    );

    await trayManager.setIcon('assets/branding/app_icon.png');
    await trayManager.setToolTip('KGMusic');
    await _refreshTrayMenu(audioHandler.playbackState.value.playing);
    _playbackSubscription = audioHandler.playbackState
        .map((state) => state.playing)
        .distinct()
        .listen((playing) {
          unawaited(
            _refreshTrayMenu(playing).catchError((Object error) {
              AppLog.warn(
                '更新托盘菜单失败',
                target: 'desktop.lifecycle',
                error: error,
              );
            }),
          );
        });
  }

  Future<void> recoverFromInitializationFailure() async {
    if (!isSupported) return;
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
    if (_listenersRegistered) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      _listenersRegistered = false;
    }
    try {
      await trayManager.destroy();
    } catch (_) {
      // The tray may not have been created yet.
    }
    if (_preventClose) {
      await windowManager.setPreventClose(false);
      _preventClose = false;
    }
  }

  Future<void> showWindow() async {
    if (!isSupported) return;
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> quit() async {
    if (!isSupported || _quitting) return;
    _quitting = true;
    AppLog.info('KGMusic 正在退出', target: 'desktop.lifecycle');
    _geometryTimer?.cancel();
    await _quitStep('保存窗口状态', _persistGeometry);
    await _quitStep('停止媒体状态监听', () async => _playbackSubscription?.cancel());
    await _quitStep('释放应用资源', shutdown);
    if (_listenersRegistered) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      _listenersRegistered = false;
    }
    await _quitStep('移除系统托盘', trayManager.destroy);
    if (_preventClose) {
      await _quitStep('恢复窗口关闭行为', () => windowManager.setPreventClose(false));
      _preventClose = false;
    }
    await _quitStep('销毁主窗口', windowManager.destroy);
    await _quitStep('终止日志与 Native 运行时', finalizeShutdown);
  }

  @override
  void onWindowClose() {
    if (!_quitting) unawaited(windowManager.hide());
  }

  @override
  void onWindowResize() => _scheduleGeometryPersistence();

  @override
  void onWindowMove() => _scheduleGeometryPersistence();

  @override
  void onWindowMaximize() {
    _maximized = true;
    _scheduleGeometryPersistence();
  }

  @override
  void onWindowUnmaximize() {
    _maximized = false;
    _scheduleGeometryPersistence();
  }

  @override
  void onTrayIconMouseDown() => unawaited(showWindow());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(showWindow());
      case 'play_pause':
        final playing = audioHandler.playbackState.value.playing;
        unawaited(playing ? audioHandler.pause() : audioHandler.play());
      case 'previous':
        unawaited(audioHandler.skipToPrevious());
      case 'next':
        unawaited(audioHandler.skipToNext());
      case 'quit':
        unawaited(quit());
    }
  }

  Future<void> _refreshTrayMenu(bool playing) => trayManager.setContextMenu(
    Menu(
      items: [
        MenuItem(key: 'show', label: 'Show KGMusic'),
        MenuItem.separator(),
        MenuItem(key: 'previous', label: 'Previous'),
        MenuItem(key: 'play_pause', label: playing ? 'Pause' : 'Play'),
        MenuItem(key: 'next', label: 'Next'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    ),
  );

  void _scheduleGeometryPersistence() {
    _geometryTimer?.cancel();
    _geometryTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_persistGeometry()),
    );
  }

  Future<void> _persistGeometry() async {
    if (!isSupported) return;
    await preferences.write(_maximizedKey, _maximized);
    if (_maximized) return;
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    await Future.wait([
      preferences.write(_widthKey, size.width),
      preferences.write(_heightKey, size.height),
      preferences.write(_xKey, position.dx),
      preferences.write(_yKey, position.dy),
    ]);
  }

  Future<bool> _canRestorePosition(Rect windowBounds) async {
    if (!windowBounds.isFinite) return false;
    try {
      final displays = await screenRetriever.getAllDisplays();
      final workAreas = displays.map((display) {
        final position = display.visiblePosition ?? Offset.zero;
        final size = display.visibleSize ?? display.size;
        return position & size;
      });
      return isRestorableWindowBounds(windowBounds, workAreas);
    } catch (error, stackTrace) {
      AppLog.warn(
        '无法验证已保存的窗口位置，将在当前屏幕居中显示',
        target: 'desktop.lifecycle',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _quitStep(
    String description,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      AppLog.warn(
        '$description失败',
        target: 'desktop.lifecycle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static PreferenceKey<double> _doubleKey(String name, double defaultValue) =>
      PreferenceKey<double>(
        name: name,
        defaultValue: defaultValue,
        decode: (value) => value is num ? value.toDouble() : null,
        encode: (value) => value,
      );
}
