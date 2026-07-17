abstract final class AuthStorageKeys {
  static const sessionV2 = 'kugou_sdk_lite_session_v2';
  static const legacySessionV1 = 'kugou_sdk_lite_session_v1';
  static const startupNotice = 'kugou_auth_startup_notice_v1';
  static const lastRefreshAt = 'kugou_lite_last_refresh_at';
}

enum AuthStartupNotice {
  securityUpgrade,
  sessionReset;

  static AuthStartupNotice? parse(String? value) {
    for (final notice in values) {
      if (notice.name == value) return notice;
    }
    return null;
  }
}
