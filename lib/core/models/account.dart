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
  });

  final int? vipType;
  final int? musicPackageType;
  final int? yearlyType;
  final String? vipEndTime;
  final String? musicEndTime;
  final String? yearlyEndTime;
  final String? productType;

  bool get active =>
      (vipType ?? 0) != 0 ||
      (musicPackageType ?? 0) != 0 ||
      (yearlyType ?? 0) != 0;
}
