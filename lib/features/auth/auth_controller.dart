import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/auth/account_session.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';

enum AuthStatus {
  booting,
  guest,
  sendingCode,
  codeSent,
  signingIn,
  authenticated,
  refreshing,
  signingOut,
  expired,
  failure,
}

/// Login UI and lifecycle coordinator. Account identity is independent of the
/// library read model; library failures are displayed by the library itself.
class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController(
    this._sdk,
    this._storage,
    this._database,
    this._library, {
    this.onSessionCleared,
    AccountSession? accountSession,
  }) : session = accountSession ?? AccountSession(),
       _ownsSession = accountSession == null;

  static const refreshInterval = Duration(hours: 12);
  static const fingerprintRetryInterval = Duration(minutes: 15);
  final AuthSdk _sdk;
  final FlutterSecureStorage _storage;
  final AppDatabase _database;
  final LibraryRepository _library;
  final AccountSession session;
  final bool _ownsSession;
  final Future<void> Function()? onSessionCleared;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  StreamSubscription<void>? _expirationSubscription;
  Future<void>? _clearing;
  bool _disposed = false;
  bool _initialized = false;
  bool _registeringDevice = false;
  DateTime? _lastFingerprintAttempt;
  DateTime? _resendAt;

  AuthStatus status = AuthStatus.booting;
  AuthSnapshot get snapshot => session.snapshot;
  String? message;
  int resendSeconds = 0;
  bool get authenticated => snapshot.authenticated;
  bool get registeringDevice => _registeringDevice;
  bool get busy =>
      _registeringDevice ||
      const {
        AuthStatus.sendingCode,
        AuthStatus.signingIn,
        AuthStatus.refreshing,
        AuthStatus.signingOut,
      }.contains(status);

  static bool isRefreshDue(DateTime? lastRefresh, DateTime now) =>
      lastRefresh == null || now.difference(lastRefresh) >= refreshInterval;
  static bool isFingerprintRetryDue(DateTime? lastAttempt, DateTime now) =>
      lastAttempt == null ||
      now.difference(lastAttempt) >= fingerprintRetryInterval;
  bool _current(int generation) => !_disposed && session.isCurrent(generation);

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _expirationSubscription = session.expirations.listen(
      (_) => unawaited(_expire()),
    );
    _refreshTimer = Timer.periodic(
      refreshInterval,
      (_) => unawaited(refreshIfDue()),
    );
    final generation = session.generation;
    try {
      final restored = await _sdk.authState();
      final notice = await _takeStartupNotice();
      if (!_current(generation)) return;
      if (restored.authenticated && restored.userId == null) {
        throw const MusicSdkException('登录信息不完整');
      }
      session.update(restored);
      status = restored.authenticated
          ? AuthStatus.authenticated
          : AuthStatus.guest;
      message = restored.authenticated
          ? null
          : switch (notice) {
              AuthStartupNotice.securityUpgrade => '设备安全信息已升级，请重新获取验证码登录。',
              AuthStartupNotice.sessionReset => '本机登录信息已失效或与当前设备不匹配，请重新登录。',
              null => null,
            };
      _notify();
      if (authenticated) {
        _startLibrary();
        await refreshIfDue();
      } else {
        await _library.deactivate();
      }
    } catch (error) {
      if (!_current(generation)) return;
      AppLog.warn('恢复登录状态失败', target: 'auth', error: error);
      status = AuthStatus.failure;
      message = '暂时无法恢复登录状态，请重试登录。';
      _notify();
    }
  }

  Future<void> sendCode(String mobile) async {
    if (busy || _disposed || resendSeconds > 0) return;
    final generation = session.generation;
    status = AuthStatus.sendingCode;
    message = null;
    _notify();
    try {
      await _sdk.sendSmsCode(mobile);
      if (!_current(generation)) return;
      status = AuthStatus.codeSent;
      _startCountdown();
    } catch (error) {
      if (!_current(generation)) return;
      AppLog.warn('请求短信验证码失败', target: 'auth', error: error);
      status = AuthStatus.failure;
      message = '验证码发送失败，请稍后重试。';
    }
    _notify();
  }

  Future<bool> login(String mobile, String code) async {
    if (busy || _disposed) return false;
    final generation = session.generation;
    status = AuthStatus.signingIn;
    message = null;
    _notify();
    try {
      final result = await _sdk.loginBySms(mobile, code);
      if (!_current(generation)) return false;
      if (!result.authenticated || result.userId == null) {
        throw const MusicSdkException('登录信息不完整');
      }
      await _markRefreshed();
      if (!_current(generation)) return false;
      session.update(result);
      _countdownTimer?.cancel();
      resendSeconds = 0;
      status = AuthStatus.authenticated;
      if (!result.fingerprintRegistered) {
        _lastFingerprintAttempt = _database.now();
        message = '登录成功，设备安全验证将在稍后重试。';
      }
      _notify();
      _startLibrary();
      return true;
    } catch (error) {
      if (!_current(generation)) return false;
      AppLog.warn('短信登录失败', target: 'auth', error: error);
      status = AuthStatus.failure;
      message = '登录失败，请检查手机号和验证码后重试。';
      _notify();
      return false;
    }
  }

  Future<void> refreshIfDue({bool force = false}) async {
    if (!authenticated || busy || _disposed) return;
    final generation = session.generation;
    // Set the gate before the first await, so resume and the timer coalesce.
    status = AuthStatus.refreshing;
    _notify();
    try {
      final raw = await _storage.read(key: AuthStorageKeys.lastRefreshAt);
      if (!_current(generation)) return;
      final last = raw == null ? null : DateTime.tryParse(raw);
      if (force || isRefreshDue(last, _database.now())) {
        final refreshed = await _sdk.refreshLogin();
        if (!_current(generation)) return;
        if (!refreshed.authenticated || refreshed.userId != snapshot.userId) {
          await _expire();
          return;
        }
        session.update(refreshed);
        await _markRefreshed();
      }
      if (!_current(generation)) return;
      message = null;
      if (!snapshot.fingerprintRegistered) {
        await _retryFingerprint(force: false);
      }
    } on MusicSdkException catch (error) {
      if (!_current(generation)) return;
      if (error.expired || error.authenticationRequired) {
        await _expire();
        return;
      }
      message = '登录状态暂时无法更新，应用稍后会自动重试。';
      AppLog.warn('刷新登录失败', target: 'auth', error: error);
    } catch (error) {
      if (!_current(generation)) return;
      message = '登录状态暂时无法更新，应用稍后会自动重试。';
      AppLog.warn('刷新登录失败', target: 'auth', error: error);
    } finally {
      if (_current(generation)) {
        status = AuthStatus.authenticated;
        _notify();
      }
    }
  }

  Future<void> retryDeviceRegistration() => _retryFingerprint(force: true);

  Future<void> _retryFingerprint({required bool force}) async {
    if (!authenticated ||
        snapshot.fingerprintRegistered ||
        _registeringDevice ||
        _disposed) {
      return;
    }
    final now = _database.now();
    if (!force && !isFingerprintRetryDue(_lastFingerprintAttempt, now)) return;
    final generation = session.generation;
    _lastFingerprintAttempt = now;
    _registeringDevice = true;
    _notify();
    try {
      final result = await _sdk.ensureDeviceRegistered();
      if (!_current(generation)) return;
      session.update(result);
      message = null;
    } catch (error) {
      if (!_current(generation)) return;
      AppLog.warn('设备安全验证失败', target: 'auth', error: error);
      message = '当前设备验证未完成，应用稍后会自动重试。';
    } finally {
      if (_current(generation)) {
        _registeringDevice = false;
        _notify();
      }
    }
  }

  Future<void> logout() => _clearSession(expired: false);
  Future<void> _expire() => _clearSession(expired: true);

  Future<void> _clearSession({required bool expired}) {
    final running = _clearing;
    if (running != null) return running;
    session.invalidate();
    status = AuthStatus.signingOut;
    _countdownTimer?.cancel();
    resendSeconds = 0;
    _registeringDevice = false;
    _lastFingerprintAttempt = null;
    _notify();
    late final Future<void> operation;
    operation =
        () async {
          var failed = false;
          Future<void> clean(Future<void> Function() action) async {
            try {
              await action();
            } catch (error) {
              failed = true;
              AppLog.warn('清理账号资源失败', target: 'auth', error: error);
            }
          }

          // Invalidate the library/player synchronously before awaiting the SDK lock.
          await Future.wait([
            clean(_library.deactivate),
            if (onSessionCleared != null) clean(onSessionCleared!),
            clean(_sdk.logout),
          ]);
          await clean(() => _storage.delete(key: AuthStorageKeys.sessionV2));
          await clean(
            () => _storage.delete(key: AuthStorageKeys.lastRefreshAt),
          );
          await clean(() => _database.clearAccountCache());
          await clean(PlaybackQueueStore(_database).clearAll);
          status = expired ? AuthStatus.expired : AuthStatus.guest;
          message = failed
              ? '本机登录信息未能完全清理，请重试退出登录。'
              : expired
              ? '登录状态已失效，请重新登录。'
              : null;
        }().whenComplete(() {
          _clearing = null;
          _notify();
        });
    _clearing = operation;
    return operation;
  }

  void _startLibrary() {
    final userId = session.userId;
    if (userId == null) return;
    unawaited(
      _library.activate(userId).catchError((Object error) {
        AppLog.warn('音乐库后台同步失败，可在音乐库重试', target: 'library.sync', error: error);
      }),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _resendAt = _database.now().add(const Duration(seconds: 60));
    resendSeconds = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSeconds =
          ((_resendAt!.difference(_database.now()).inMilliseconds + 999) ~/
                  1000)
              .clamp(0, 60);
      if (resendSeconds == 0) timer.cancel();
      _notify();
    });
  }

  Future<void> _markRefreshed() async {
    try {
      await _storage.write(
        key: AuthStorageKeys.lastRefreshAt,
        value: _database.now().toUtc().toIso8601String(),
      );
    } catch (error) {
      AppLog.warn('保存登录刷新时间失败', target: 'auth', error: error);
    }
  }

  Future<AuthStartupNotice?> _takeStartupNotice() async {
    final raw = await _storage.read(key: AuthStorageKeys.startupNotice);
    if (raw != null) await _storage.delete(key: AuthStorageKeys.startupNotice);
    return AuthStartupNotice.parse(raw);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_resume());
  }

  Future<void> _resume() async {
    await refreshIfDue();
    if (authenticated) {
      try {
        await _library.syncIfDue();
      } catch (error) {
        AppLog.warn('恢复前台同步失败', target: 'library.sync', error: error);
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    unawaited(_expirationSubscription?.cancel());
    if (_ownsSession) unawaited(session.dispose());
    super.dispose();
  }
}
