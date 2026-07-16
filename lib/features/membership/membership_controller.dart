import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/providers.dart';
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
    this._onMembershipChanged,
  );

  final MembershipSdk _sdk;
  final FlutterSecureStorage _storage;
  final int userId;
  final Future<void> Function() _refreshLogin;
  final Future<void> Function() _onMembershipChanged;

  MembershipAction action = MembershipAction.idle;
  VipMonthRecord? record;
  String? recordError;
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
  String get _today => vipDateKey(DateTime.now());
  String get _claimKey => 'kugou_lite_vip_claimed_$userId';
  String get _upgradeKey => 'kugou_lite_vip_upgraded_$userId';

  Future<void> initialize() async {
    _claimedDate = await _storage.read(key: _claimKey);
    _upgradedDate = await _storage.read(key: _upgradeKey);
    _notify();
  }

  Future<void> loadRecord() async {
    if (action == MembershipAction.loadingRecord || record != null) return;
    action = MembershipAction.loadingRecord;
    recordError = null;
    _notify();
    try {
      record = await _sdk.monthVipRecord();
    } catch (error) {
      recordError = error.toString();
    } finally {
      action = MembershipAction.idle;
      _notify();
    }
  }

  Future<VipClaimResult> claim() async {
    if (busy) throw const MusicSdkException('已有会员操作正在进行');
    if (claimedToday) throw const MusicSdkException('今天已经领取过会员权益');
    action = MembershipAction.claiming;
    refreshWarning = null;
    _notify();
    try {
      final result = await _sdk.claimDayVip();
      final claimedAt = result.serverTimeSecs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(
              result.serverTimeSecs! * 1000,
              isUtc: true,
            ).toLocal();
      _claimedDate = vipDateKey(claimedAt);
      try {
        await _storage.write(key: _claimKey, value: _claimedDate);
      } catch (error) {
        refreshWarning = '本地防重复状态保存失败：$error';
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
    if (busy) throw const MusicSdkException('已有会员操作正在进行');
    if (upgradedToday) throw const MusicSdkException('今天已经升级过畅听会员');
    action = MembershipAction.upgrading;
    refreshWarning = null;
    _notify();
    try {
      final result = await _sdk.upgradeDayVip();
      _upgradedDate = _today;
      try {
        await _storage.write(key: _upgradeKey, value: _upgradedDate);
      } catch (error) {
        refreshWarning = '本地防重复状态保存失败：$error';
      }
      await _refreshMembership();
      return result;
    } finally {
      action = MembershipAction.idle;
      _notify();
    }
  }

  Future<void> _refreshMembership() async {
    try {
      await _refreshLogin();
    } catch (error) {
      refreshWarning = '会员已生效，但登录信息刷新失败：$error';
    }
    try {
      await _onMembershipChanged();
    } catch (error) {
      refreshWarning ??= '会员已生效，但页面状态刷新失败：$error';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
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
        () async => ref.invalidate(userVipProvider),
      );
      unawaited(controller.initialize());
      return controller;
    });
