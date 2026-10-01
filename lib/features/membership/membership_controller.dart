import 'dart:async';

import 'package:kgmusic/core/auth/account_session.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/features/membership/membership_presenter.dart';

enum MembershipAction { idle, loadingRecord, claiming, upgrading }

class MembershipController extends ChangeNotifier {
  MembershipController(
    this._sdk,
    this._storage,
    this.userId,
    this._refreshLogin,
    this._onMembershipChanged, {
    AccountSession? accountSession,
    DateTime Function()? now,
  }) : _session = accountSession,
       _generation = accountSession?.generation,
       _now = now ?? DateTime.now;

  final MembershipSdk _sdk;
  final AccountSession? _session;
  final int? _generation;
  final DateTime Function() _now;
  Future<void>? _initialization;
  String? _recordMonth;
  bool get _current =>
      !_disposed &&
      (_session == null ||
          (_session.isCurrent(_generation!) && _session.userId == userId));
  void _requireCurrent() {
    if (!_current) throw const StaleSessionException();
  }

  final FlutterSecureStorage _storage;
  final int userId;
  final Future<void> Function() _refreshLogin;
  final Future<void> Function() _onMembershipChanged;

  MembershipAction action = MembershipAction.idle;
  VipMonthRecord? record;
  bool recordUnavailable = false;
  String? refreshWarning;
  String? _claimedDate;
  String? _upgradedDate;
  bool _disposed = false;

  bool get busy => action != MembershipAction.idle;
  bool get claimedToday =>
      _claimedDate == _today ||
      (record?.claimDates
              .map(vipDateKeyFromRaw)
              .whereType<String>()
              .contains(_today) ??
          false);
  bool get upgradedToday => _upgradedDate == _today;
  String get _today => vipDateKey(_now());
  String get _claimKey => 'kugou_lite_vip_claimed_$userId';
  String get _upgradeKey => 'kugou_lite_vip_upgraded_$userId';

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      final claimed = await _storage.read(key: _claimKey);
      final upgraded = await _storage.read(key: _upgradeKey);
      if (!_current) return;
      _claimedDate = claimed;
      _upgradedDate = upgraded;
    } catch (error) {
      AppLog.warn('读取会员本机状态失败', target: 'membership', error: error);
    }
    _notify();
  }

  Future<void> loadRecord() async {
    await initialize();
    if (!_current ||
        busy ||
        (record != null && _recordMonth == _today.substring(0, 7))) {
      return;
    }
    action = MembershipAction.loadingRecord;
    recordUnavailable = false;
    _notify();
    try {
      final result = await _sdk.monthVipRecord();
      if (!_current) return;
      record = result;
      _recordMonth = _today.substring(0, 7);
    } catch (error) {
      AppLog.warn('读取会员领取记录失败', target: 'membership', error: error);
      recordUnavailable = true;
    } finally {
      action = MembershipAction.idle;
      _notify();
    }
  }

  Future<VipClaimResult> claim() async {
    await initialize();
    _requireCurrent();
    if (busy) throw const MusicSdkException('已有会员操作正在进行');
    if (claimedToday) throw const MusicSdkException('今天已经领取过会员权益');
    action = MembershipAction.claiming;
    refreshWarning = null;
    _notify();
    try {
      final result = await _sdk.claimDayVip();
      _requireCurrent();
      final claimedAt = result.serverTimeSecs == null
          ? _now()
          : DateTime.fromMillisecondsSinceEpoch(
              result.serverTimeSecs! * 1000,
              isUtc: true,
            ).toLocal();
      _claimedDate = vipDateKey(claimedAt);
      try {
        await _storage.write(key: _claimKey, value: _claimedDate);
      } catch (error) {
        AppLog.warn('保存会员领取状态失败', target: 'membership', error: error);
        refreshWarning = '权益已生效，但本机状态未能更新，请避免重复领取。';
      }
      record = VipMonthRecord(
        claimedDays: record?.claimedDays == null
            ? null
            : record!.claimedDays! + 1,
        claimDates: {...?record?.claimDates, _claimedDate!}.toList(),
      );
      await _refreshMembership();
      return result;
    } finally {
      action = MembershipAction.idle;
      _notify();
    }
  }

  Future<VipUpgradeResult> upgrade() async {
    await initialize();
    _requireCurrent();
    if (busy) throw const MusicSdkException('已有会员操作正在进行');
    if (upgradedToday) throw const MusicSdkException('今天已经升级过畅听会员');
    action = MembershipAction.upgrading;
    refreshWarning = null;
    _notify();
    try {
      final result = await _sdk.upgradeDayVip();
      _requireCurrent();
      _upgradedDate = _today;
      try {
        await _storage.write(key: _upgradeKey, value: _upgradedDate);
      } catch (error) {
        AppLog.warn('保存会员升级状态失败', target: 'membership', error: error);
        refreshWarning = '权益已生效，但本机状态未能更新，请避免重复升级。';
      }
      await _refreshMembership();
      return result;
    } finally {
      action = MembershipAction.idle;
      _notify();
    }
  }

  Future<void> _refreshMembership() async {
    if (!_current) return;
    try {
      await _refreshLogin();
    } catch (error) {
      AppLog.warn('刷新会员登录状态失败', target: 'membership', error: error);
      refreshWarning = '权益已生效，会员状态将在稍后自动更新。';
    }
    if (!_current) return;
    try {
      await _onMembershipChanged();
    } catch (error) {
      AppLog.warn('刷新会员页面状态失败', target: 'membership', error: error);
      refreshWarning ??= '权益已生效，会员状态将在稍后自动更新。';
    }
  }

  void _notify() {
    if (_current) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final membershipControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MembershipController, int>((ref, userId) {
      final controller = MembershipController(
        ref.read(musicSdkProvider),
        ref.read(secureStorageProvider),
        userId,
        () => ref.read(authControllerProvider).refreshIfDue(force: true),
        () async {
          await ref
              .read(musicRepositoryProvider)
              .userVip(userId, mode: CacheLoadMode.forceRefresh)
              .last;
          ref.invalidate(userVipProvider);
        },
        accountSession: ref.read(accountSessionProvider),
        now: ref.read(databaseProvider).now,
      );
      unawaited(controller.initialize());
      return controller;
    });
