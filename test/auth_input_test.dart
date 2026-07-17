import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/features/auth/auth_input.dart';

void main() {
  test('手机号校验与 SDK 接受范围一致', () {
    expect(validateMobile('13800138000'), isNull);
    expect(validateMobile('+8613800138000'), isNull);
    expect(validateMobile('123'), isNotNull);
    expect(validateMobile('13800abc000'), isNotNull);
  });

  test('验证码仅接受 4 到 8 位数字', () {
    expect(validateSmsCode('1234'), isNull);
    expect(validateSmsCode('12345678'), isNull);
    expect(validateSmsCode('123'), isNotNull);
    expect(validateSmsCode('12ab'), isNotNull);
  });
}
