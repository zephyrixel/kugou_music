import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';

void main() {
  test('refresh is due without a previous successful refresh', () {
    expect(
      AuthController.isRefreshDue(null, DateTime.utc(2026, 7, 14)),
      isTrue,
    );
  });

  test('refresh becomes due after twelve hours', () {
    final last = DateTime.utc(2026, 7, 14, 1);
    expect(
      AuthController.isRefreshDue(last, last.add(const Duration(hours: 11))),
      isFalse,
    );
    expect(
      AuthController.isRefreshDue(last, last.add(const Duration(hours: 12))),
      isTrue,
    );
  });

  test('device registration retries are throttled for fifteen minutes', () {
    final last = DateTime.utc(2026, 7, 17, 1);
    expect(
      AuthController.isFingerprintRetryDue(
        last,
        last.add(const Duration(minutes: 14)),
      ),
      isFalse,
    );
    expect(
      AuthController.isFingerprintRetryDue(
        last,
        last.add(const Duration(minutes: 15)),
      ),
      isTrue,
    );
  });

  test('startup notice ignores unknown persisted values', () {
    expect(
      AuthStartupNotice.parse('securityUpgrade'),
      AuthStartupNotice.securityUpgrade,
    );
    expect(AuthStartupNotice.parse('future-value'), isNull);
  });
}
