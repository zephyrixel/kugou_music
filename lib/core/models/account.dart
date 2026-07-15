class AuthSnapshot {
  const AuthSnapshot({
    required this.authenticated,
    required this.fingerprintRegistered,
    this.userId,
    this.vipType,
  });

  final bool authenticated;
  final int? userId;
  final int? vipType;
  final bool fingerprintRegistered;
}

class SmsLoginResult {
  const SmsLoginResult({required this.auth, this.fingerprintWarning});
  final AuthSnapshot auth;
  final String? fingerprintWarning;
}

class UserProfile {
  const UserProfile({
    required this.displayName,
    this.userId,
    this.username,
    this.avatarUrl,
    this.gender,
    this.birthday,
    this.city,
    this.province,
    this.signature,
    this.followingCount,
    this.fanCount,
    this.visitorCount,
  });

  final int? userId;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final int? gender;
  final String? birthday;
  final String? city;
  final String? province;
  final String? signature;
  final int? followingCount;
  final int? fanCount;
  final int? visitorCount;
}

class UserVip {
  const UserVip({
    this.vipType,
    this.musicPackageType,
    this.yearlyType,
    this.vipEndTime,
    this.musicEndTime,
    this.yearlyEndTime,
    this.productType,
    this.businessType,
    this.products = const [],
  });

  final int? vipType;
  final int? musicPackageType;
  final int? yearlyType;
  final String? vipEndTime;
  final String? musicEndTime;
  final String? yearlyEndTime;
  final String? productType;
  final String? businessType;
  final List<VipProduct> products;

  bool get active =>
      products.any((product) => product.active) ||
      ((vipType ?? 0) != 0 && vipType != 5) ||
      ((musicPackageType ?? 0) > 0 && (musicPackageType ?? 0) < 5) ||
      yearlyType == 1;
}

class VipProduct {
  const VipProduct({
    this.productType,
    this.businessType,
    required this.active,
    required this.paid,
    required this.yearly,
    this.vipEndTime,
    this.paidExpireTime,
  });

  final String? productType;
  final String? businessType;
  final bool active;
  final bool paid;
  final bool yearly;
  final String? vipEndTime;
  final String? paidExpireTime;

  String? get effectiveEndTime => vipEndTime ?? paidExpireTime;
}

class VipClaimResult {
  const VipClaimResult({this.grantedUnits, this.endTime, this.serverTimeSecs});

  final int? grantedUnits;
  final String? endTime;
  final int? serverTimeSecs;
}

class VipUpgradeResult {
  const VipUpgradeResult({this.statusCode, this.message, this.endTime});

  final int? statusCode;
  final String? message;
  final String? endTime;
}

class VipMonthRecord {
  const VipMonthRecord({this.claimedDays, this.claimDates = const []});

  final int? claimedDays;
  final List<String> claimDates;
}
