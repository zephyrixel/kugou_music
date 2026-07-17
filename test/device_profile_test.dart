import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/platform/device_profile.dart';

void main() {
  test('Android 设备标识拒绝已知占位值', () {
    expect(normalizeAndroidDeviceId('abcDEF123'), 'abcDEF123');
    expect(normalizeAndroidDeviceId('9774d56d682e549c'), isNull);
    expect(normalizeAndroidDeviceId('0000000000000000'), isNull);
    expect(normalizeAndroidDeviceId('unknown'), isNull);
    expect(normalizeAndroidDeviceId('  '), isNull);
  });
}
