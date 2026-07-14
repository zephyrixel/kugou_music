import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

enum AuthStatus {
  booting,
  guest,
  sendingCode,
  codeSent,
  signingIn,
  authenticated,
  refreshing,
  expired,
  failure,
}

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController(this._sdk, this._storage, this._database);

  static const refreshInterval = Duration(hours: 12);
  static const _lastRefreshKey = 'kugou_lite_last_refresh_at';

  final MusicSdk _sdk;
  final FlutterSecureStorage _storage;
  final AppDatabase _database;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  bool _disposed = false;

  AuthStatus status = AuthStatus.booting;
  AuthSnapshot snapshot = const AuthSnapshot(
    authenticated: false,
    fingerprintRegistered: false,
  );
  String? message;
  int resendSeconds = 0;

  bool get authenticated => snapshot.authenticated;
  bool get busy => const {
    AuthStatus.sendingCode,
    AuthStatus.signingIn,
    AuthStatus.refreshing,
  }.contains(status);

  static bool isRefreshDue(DateTime? lastRefresh, DateTime now) =>
      lastRefresh == null || now.difference(lastRefresh) >= refreshInterval;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(refreshInterval, (_) => refreshIfDue());
    try {
      snapshot = await _sdk.authState();
      status = snapshot.authenticated
          ? AuthStatus.authenticated
          : AuthStatus.guest;
      _notify();
      if (snapshot.authenticated) await refreshIfDue();
    } catch (error) {
      status = AuthStatus.failure;
      message = error.toString();
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
      message = error.toString();
    }
    _notify();
  }

  Future<bool> login(String mobile, String code) async {
    status = AuthStatus.signingIn;
    message = null;
    _notify();
    try {
      final result = await _sdk.loginBySms(mobile, code);
      snapshot = result.auth;
      status = AuthStatus.authenticated;
      message = result.fingerprintWarning == null ? null : '登录成功，设备指纹将在稍后重试注册';
      await _markRefreshed();
      _countdownTimer?.cancel();
      resendSeconds = 0;
      _notify();
      return true;
    } catch (error) {
      status = AuthStatus.failure;
      message = error.toString();
      _notify();
      return false;
    }
  }

  Future<void> refreshIfDue({bool force = false}) async {
    if (!snapshot.authenticated || status == AuthStatus.refreshing) return;
    final raw = await _storage.read(key: _lastRefreshKey);
    final last = raw == null ? null : DateTime.tryParse(raw);
    if (!force && !isRefreshDue(last, DateTime.now())) {
      if (!snapshot.fingerprintRegistered) await _retryFingerprint();
      return;
    }
    status = AuthStatus.refreshing;
    message = null;
    _notify();
    try {
      snapshot = await _sdk.refreshLogin();
      status = AuthStatus.authenticated;
      await _markRefreshed();
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

  Future<void> _retryFingerprint() async {
    try {
      snapshot = await _sdk.registerDevice();
      _notify();
    } catch (_) {
      // A valid login is more valuable than blocking the app on risk service.
    }
  }

  Future<void> logout() async {
    await _sdk.logout();
    await _storage.delete(key: _lastRefreshKey);
    await _database.clearAccountCache();
    snapshot = const AuthSnapshot(
      authenticated: false,
      fingerprintRegistered: false,
    );
    status = AuthStatus.guest;
    message = null;
    _notify();
  }

  Future<void> _expire(String reason) async {
    await _sdk.logout();
    await _storage.delete(key: _lastRefreshKey);
    await _database.clearAccountCache();
    snapshot = const AuthSnapshot(
      authenticated: false,
      fingerprintRegistered: false,
    );
    status = AuthStatus.expired;
    message = reason;
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
    key: _lastRefreshKey,
    value: DateTime.now().toUtc().toIso8601String(),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refreshIfDue());
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
