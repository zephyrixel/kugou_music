import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/features/membership/membership_presenter.dart';

void main() {
  test(
    'membership summary keeps parallel products and selects Lite priority',
    () {
      const vip = UserVip(
        musicPackageType: 1,
        musicEndTime: '2026-10-01',
        products: [
          VipProduct(
            productType: 'tvip',
            active: true,
            paid: false,
            yearly: false,
            vipEndTime: '2026-08-01',
          ),
          VipProduct(
            productType: 'svip',
            active: true,
            paid: true,
            yearly: true,
            vipEndTime: '2026-09-01',
          ),
          VipProduct(
            productType: 'future_vip',
            active: true,
            paid: false,
            yearly: false,
          ),
        ],
      );

      final summary = buildMembershipSummary(vip, now: DateTime(2026, 7, 15));

      expect(summary.primary?.label, '豪华 VIP');
      expect(summary.items.map((item) => item.label), [
        '豪华 VIP',
        '畅听 VIP',
        '音乐包',
        'FUTURE_VIP',
      ]);
      expect(summary.primary?.yearly, isTrue);
      expect(summary.primary?.paid, isTrue);
    },
  );

  test('vip type 5 is inactive and latest expired date is displayed', () {
    const vip = UserVip(
      vipType: 5,
      vipEndTime: '2026-03-01',
      products: [
        VipProduct(
          productType: 'dvip',
          active: false,
          paid: false,
          yearly: false,
          vipEndTime: '2026-04-02',
        ),
      ],
    );

    final summary = buildMembershipSummary(vip, now: DateTime(2026, 7, 15));

    expect(vip.active, isFalse);
    expect(summary.items, isEmpty);
    expect(summary.statusLabel, '已于 2026-04-02 到期');
  });

  test('VIP times accept seconds, milliseconds and compact dates', () {
    expect(parseVipTime('1700000000')?.millisecondsSinceEpoch, 1700000000000);
    expect(
      parseVipTime('1700000000000')?.millisecondsSinceEpoch,
      1700000000000,
    );
    expect(vipDateKeyFromRaw('20260715'), '2026-07-15');
  });
}
