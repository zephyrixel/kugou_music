import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/features/membership/membership_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'claim is manual, refreshes membership and blocks same-day repeats',
    () async {
      final sdk = _MembershipSdk();
      var refreshCalls = 0;
      var changedCalls = 0;
      final controller = MembershipController(
        sdk,
        const FlutterSecureStorage(),
        42,
        () async => refreshCalls += 1,
        () async => changedCalls += 1,
      );
      await controller.initialize();

      await controller.claim();

      expect(sdk.claimCalls, 1);
      expect(sdk.upgradeCalls, 0);
      expect(refreshCalls, 1);
      expect(changedCalls, 1);
      expect(controller.claimedToday, isTrue);
      await expectLater(controller.claim(), throwsA(isA<MusicSdkException>()));
      expect(sdk.claimCalls, 1);

      final restored = MembershipController(
        sdk,
        const FlutterSecureStorage(),
        42,
        () async {},
        () async {},
      );
      await restored.initialize();
      expect(restored.claimedToday, isTrue);
    },
  );

  test(
    'month record is lazy and upgrade stays an explicit separate action',
    () async {
      final sdk = _MembershipSdk();
      final controller = MembershipController(
        sdk,
        const FlutterSecureStorage(),
        7,
        () async {},
        () async {},
      );
      await controller.initialize();

      expect(sdk.recordCalls, 0);
      await controller.loadRecord();
      expect(sdk.recordCalls, 1);
      expect(controller.claimedToday, isTrue);

      await controller.upgrade();
      expect(sdk.upgradeCalls, 1);
      expect(controller.upgradedToday, isTrue);
    },
  );

  test(
    'refresh failure does not turn a successful claim into a failure',
    () async {
      final sdk = _MembershipSdk();
      final controller = MembershipController(
        sdk,
        const FlutterSecureStorage(),
        8,
        () async => throw StateError('refresh failed'),
        () async {},
      );
      await controller.initialize();

      final result = await controller.claim();

      expect(result.grantedUnits, 1);
      expect(controller.claimedToday, isTrue);
      expect(controller.refreshWarning, contains('登录信息刷新失败'));
    },
  );
}

class _MembershipSdk implements MusicSdk {
  int claimCalls = 0;
  int upgradeCalls = 0;
  int recordCalls = 0;

  @override
  Future<VipClaimResult> claimDayVip() async {
    claimCalls += 1;
    return VipClaimResult(
      grantedUnits: 1,
      endTime: '2026-07-16',
      serverTimeSecs: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  @override
  Future<VipUpgradeResult> upgradeDayVip() async {
    upgradeCalls += 1;
    return const VipUpgradeResult(message: 'ok');
  }

  @override
  Future<VipMonthRecord> monthVipRecord() async {
    recordCalls += 1;
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return VipMonthRecord(claimedDays: 1, claimDates: [date]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
