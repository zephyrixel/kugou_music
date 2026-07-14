import 'package:flutter_test/flutter_test.dart';
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
}
