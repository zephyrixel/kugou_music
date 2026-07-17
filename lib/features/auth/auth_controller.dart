import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

enum AuthStatus {
  booting,
  guest,
  sendingCode,
  codeSent,
  signingIn,
  syncingLibrary,
  authenticated,
  refreshing,
  expired,
  failure,
}

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController(
    this._sdk,
    this._storage,
    this._database,
    this._library, {
    this.onSessionCleared,
  });

  static const refreshInterval = Duration(hours: 12);
  static const fingerprintRetryInterval = Duration(minutes: 15);

  final AuthSdk _sdk;
  final FlutterSecureStorage _storage;
  final AppDatabase _database;
  final LibraryRepository _library;
  final Future<void> Function()? onSessionCleared;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  bool _disposed = false;
  bool _libraryReady = false;
  bool _registeringDevice = false;
  DateTime? _lastFingerprintAttempt;

  AuthStatus status = AuthStatus.booting;
  AuthSnapshot snapshot = const AuthSnapshot(
    authenticated: false,
    fingerprintRegistered: false,
  );
  String? message;
  int resendSeconds = 0;

  bool get authenticated => snapshot.authenticated && _libraryReady;
  bool get registeringDevice => _registeringDevice;
  bool get busy =>
      _registeringDevice ||
      const {
        AuthStatus.sendingCode,
        AuthStatus.signingIn,
        AuthStatus.syncingLibrary,
        AuthStatus.refreshing,
      }.contains(status);

  static bool isRefreshDue(DateTime? lastRefresh, DateTime now) =>
      lastRefresh == null || now.difference(lastRefresh) >= refreshInterval;

  static bool isFingerprintRetryDue(DateTime? lastAttempt, DateTime now) =>
      lastAttempt == null ||
      now.difference(lastAttempt) >= fingerprintRetryInterval;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(refreshInterval, (_) => refreshIfDue());
    try {
      snapshot = await _sdk.authState();
      final startupNotice = await _takeStartupNotice();
      if (snapshot.authenticated) {
        await _initializeLibrary();
        if (authenticated) await refreshIfDue();
      } else {
        await _library.deactivate();
        status = AuthStatus.guest;
        message = switch (startupNotice) {
          AuthStartupNotice.securityUpgrade => '设备安全信息已升级，请重新获取验证码登录。',
          AuthStartupNotice.sessionReset => '本机登录信息已失效或与当前设备不匹配，请重新登录。',
          null => null,
        };
        _notify();
      }
    } catch (error) {
      status = AuthStatus.failure;
      message = '恢复登录状态失败：$error';
      _notify();
    }
  }

  Future<void> sendCode(String mobile) async {
    status = AuthStatus.sendingCode;
    message = null;
    _notify();
    try {
      await _sdk.sendSmsCode(mobile);
      status = AuthStatus.codeSent;
      _startCountdown();
    } catch (error) {
      status = AuthStatus.failure;
      message = '获取验证码失败：$error';
    }
    _notify();
  }

  Future<bool> login(String mobile, String code) async {
    status = AuthStatus.signingIn;
    message = null;
    _notify();
    try {
      snapshot = await _sdk.loginBySms(mobile, code);
      final registrationPending = !snapshot.fingerprintRegistered;
      if (registrationPending) {
        _lastFingerprintAttempt = DateTime.now();
      }
      await _markRefreshed();
      _countdownTimer?.cancel();
      resendSeconds = 0;
      await _initializeLibrary();
      if (authenticated && registrationPending) {
        message = '登录成功，但设备登记尚未完成，可在个人中心重试。';
        _notify();
      }
      return authenticated;
    } catch (error) {
      status = AuthStatus.failure;
      message = '登录失败：$error';
      _notify();
      return false;
    }
  }

  Future<void> refreshIfDue({bool force = false}) async {
    if (!authenticated ||
        status == AuthStatus.refreshing ||
        _registeringDevice) {
      return;
    }
    final raw = await _storage.read(key: AuthStorageKeys.lastRefreshAt);
    final last = raw == null ? null : DateTime.tryParse(raw);
    if (!force && !isRefreshDue(last, DateTime.now())) {
      if (!snapshot.fingerprintRegistered) {
        await _retryFingerprint(force: false);
      }
      return;
    }
    status = AuthStatus.refreshing;
    message = null;
    _notify();
    try {
      snapshot = await _sdk.refreshLogin();
      status = AuthStatus.authenticated;
      await _markRefreshed();
      if (!snapshot.fingerprintRegistered) {
        await _retryFingerprint(force: false);
      }
    } on MusicSdkException catch (error) {
      if (error.expired || error.authenticationRequired) {
        await _expire(error.message);
        return;
      }
      status = AuthStatus.authenticated;
      message = '登录信息刷新失败，将在稍后重试：${error.message}';
    } catch (error) {
      status = AuthStatus.authenticated;
      message = '登录信息刷新失败，将在稍后重试：$error';
    }
    _notify();
  }

  Future<void> retryDeviceRegistration() => _retryFingerprint(force: true);

  Future<void> _retryFingerprint({required bool force}) async {
    if (snapshot.fingerprintRegistered || _registeringDevice) return;
    final now = DateTime.now();
    if (!force && !isFingerprintRetryDue(_lastFingerprintAttempt, now)) {
      return;
    }
    _lastFingerprintAttempt = now;
    _registeringDevice = true;
    _notify();
    try {
      snapshot = await _sdk.ensureDeviceRegistered();
      message = null;
    } catch (error) {
      message = '设备登记失败，将在稍后重试：$error';
    } finally {
      _registeringDevice = false;
      _notify();
    }
  }

  Future<void> logout() => _clearSession(next: AuthStatus.guest);

  Future<void> _expire(String reason) =>
      _clearSession(next: AuthStatus.expired, message: reason);

  Future<void> _clearSession({
    required AuthStatus next,
    String? message,
  }) async {
    await _sdk.logout();
    await onSessionCleared?.call();
    await _storage.delete(key: AuthStorageKeys.lastRefreshAt);
    await _database.clearAccountCache();
    await _library.deactivate();
    _libraryReady = false;
    _registeringDevice = false;
    _lastFingerprintAttempt = null;
    snapshot = const AuthSnapshot(
      authenticated: false,
      fingerprintRegistered: false,
    );
    status = next;
    this.message = message;
    _notify();
  }

  Future<void> retryLibraryInitialization() async {
    if (!snapshot.authenticated) return;
    await _initializeLibrary();
  }

  Future<void> _initializeLibrary() async {
    final userId = snapshot.userId;
    if (userId == null) {
      status = AuthStatus.failure;
      message = '登录响应缺少用户 ID';
      _libraryReady = false;
      _notify();
      return;
    }
    status = AuthStatus.syncingLibrary;
    _libraryReady = false;
    _notify();
    try {
      await _library.activate(userId);
      _libraryReady = true;
      status = AuthStatus.authenticated;
      message = null;
    } catch (error) {
      status = AuthStatus.failure;
      message = '初始化音乐库失败：$error';
    }
    _notify();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    resendSeconds = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSeconds -= 1;
      if (resendSeconds <= 0) timer.cancel();
      _notify();
    });
  }

  Future<void> _markRefreshed() => _storage.write(
    key: AuthStorageKeys.lastRefreshAt,
    value: DateTime.now().toUtc().toIso8601String(),
  );

  Future<AuthStartupNotice?> _takeStartupNotice() async {
    final raw = await _storage.read(key: AuthStorageKeys.startupNotice);
    if (raw != null) {
      await _storage.delete(key: AuthStorageKeys.startupNotice);
    }
    return AuthStartupNotice.parse(raw);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_resume());
  }

  Future<void> _resume() async {
    await refreshIfDue();
    if (authenticated) await _library.syncIfDue();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
