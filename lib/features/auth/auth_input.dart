String? validateMobile(String value) {
  final input = value.trim();
  final digits = input.startsWith('+') ? input.substring(1) : input;
  if (digits.length < 7 ||
      digits.length > 20 ||
      digits.contains(RegExp(r'[^0-9]'))) {
    return '请输入 7–20 位手机号，可包含开头的 +';
  }
  return null;
}

String? validateSmsCode(String value) {
  final input = value.trim();
  if (input.length < 4 ||
      input.length > 8 ||
      input.contains(RegExp(r'[^0-9]'))) {
    return '请输入 4–8 位数字验证码';
  }
  return null;
}
