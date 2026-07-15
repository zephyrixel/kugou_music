import 'package:kgmusic/core/models/account.dart';

class MembershipDisplayItem {
  const MembershipDisplayItem({
    required this.code,
    required this.label,
    required this.priority,
    this.endTime,
    this.paid = false,
    this.yearly = false,
  });

  final String code;
  final String label;
  final int priority;
  final DateTime? endTime;
  final bool paid;
  final bool yearly;

  String get expiryLabel =>
      endTime == null ? '有效期以酷狗账号为准' : '有效至 ${formatVipDate(endTime!)}';
}

class MembershipSummary {
  const MembershipSummary({required this.items, this.lastExpiredAt});

  final List<MembershipDisplayItem> items;
  final DateTime? lastExpiredAt;

  bool get active => items.isNotEmpty;
  MembershipDisplayItem? get primary => items.firstOrNull;

  String get statusLabel {
    final current = primary;
    if (current != null) return current.expiryLabel;
    final expiredAt = lastExpiredAt;
    return expiredAt == null ? '暂未开通会员' : '已于 ${formatVipDate(expiredAt)} 到期';
  }
}

MembershipSummary buildMembershipSummary(UserVip vip, {DateTime? now}) {
  final items = <MembershipDisplayItem>[];
  final seen = <String>{};

  for (final product in vip.products.where((product) => product.active)) {
    final code = product.productType?.trim().toLowerCase();
    if (code == null || code.isEmpty || !seen.add(code)) continue;
    items.add(
      MembershipDisplayItem(
        code: code,
        label: membershipLabel(code),
        priority: membershipPriority(code),
        endTime: parseVipTime(product.effectiveEndTime),
        paid: product.paid,
        yearly: product.yearly,
      ),
    );
  }

  final vipType = vip.vipType ?? 0;
  if (vipType != 0 && vipType != 5 && !seen.contains('svip')) {
    items.add(
      MembershipDisplayItem(
        code: 'classic_vip',
        label: '音乐 VIP',
        priority: 95,
        endTime: parseVipTime(vip.vipEndTime),
        yearly: vip.yearlyType == 1,
      ),
    );
  }

  final musicType = vip.musicPackageType ?? 0;
  if (musicType > 0 && musicType < 5) {
    items.add(
      MembershipDisplayItem(
        code: 'music_package',
        label: '音乐包',
        priority: 65,
        endTime: parseVipTime(vip.musicEndTime),
      ),
    );
  }

  if (vip.yearlyType == 1 && !items.any((item) => item.yearly)) {
    items.add(
      MembershipDisplayItem(
        code: 'yearly',
        label: '年费权益',
        priority: 55,
        endTime: parseVipTime(vip.yearlyEndTime),
        yearly: true,
      ),
    );
  }

  items.sort((left, right) => right.priority.compareTo(left.priority));
  final current = now ?? DateTime.now();
  final knownEnds =
      <DateTime?>[
            parseVipTime(vip.vipEndTime),
            parseVipTime(vip.musicEndTime),
            parseVipTime(vip.yearlyEndTime),
            ...vip.products.expand(
              (product) => [
                parseVipTime(product.vipEndTime),
                parseVipTime(product.paidExpireTime),
              ],
            ),
          ]
          .whereType<DateTime>()
          .where((value) => value.isBefore(current))
          .toList()
        ..sort();

  return MembershipSummary(
    items: List.unmodifiable(items),
    lastExpiredAt: knownEnds.lastOrNull,
  );
}

String membershipLabel(String code) => switch (code.toLowerCase()) {
  'svip' => '豪华 VIP',
  'wvip' => '周卡 VIP',
  'tvip' => '畅听 VIP',
  'qvip' => 'Q 会员',
  'dvip' => '日卡 VIP',
  _ => code.toUpperCase(),
};

int membershipPriority(String code) => switch (code.toLowerCase()) {
  'svip' => 100,
  'wvip' => 90,
  'tvip' => 80,
  'qvip' => 70,
  'dvip' => 60,
  _ => 10,
};

DateTime? parseVipTime(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || value == '0' || value == '-') {
    return null;
  }
  final numeric = int.tryParse(value);
  if (numeric != null) {
    if (numeric >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        numeric,
        isUtc: true,
      ).toLocal();
    }
    if (numeric >= 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(
        numeric * 1000,
        isUtc: true,
      ).toLocal();
    }
    if (value.length == 8) {
      return DateTime.tryParse(
        '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6)}',
      );
    }
  }
  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

String formatVipDate(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String vipDateKey(DateTime value) => formatVipDate(value.toLocal());

String? vipDateKeyFromRaw(String raw) {
  final parsed = parseVipTime(raw);
  return parsed == null ? null : vipDateKey(parsed);
}
