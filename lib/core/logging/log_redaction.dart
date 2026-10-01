const _secretKeys =
    'sessionJson|session_json|uuid|access_token|vip_token|token|authorization|cookie|password|passwd|signature|sms_code|smscode|verify_code|android_id|androidId|device_id|deviceId|dfid|guid|mid';
final _jsonSecrets = RegExp(
  '("(?:$_secretKeys)"\\s*:\\s*)("(?:\\\\.|[^"\\\\])*"|[^,\\s}]+)',
  caseSensitive: false,
);
final _headers = RegExp(
  r'\b(authorization|cookie)(\s*[:=]\s*)[^\r\n]+',
  caseSensitive: false,
);
final _fields = RegExp(
  '\\b($_secretKeys)(\\s*[=:]\\s*)([^\\s&,;}]+)',
  caseSensitive: false,
);
final _codes = RegExp(r'(验证码\s*[=:：]\s*)\d{4,8}');
final _jsonCodes = RegExp(r'("code"\s*:\s*)"\d{4,8}"');
final _phones = RegExp(r'(?<!\d)1\d{10}(?!\d)');

/// Applies equally to ordinary logs, Trace, and exports of older log files.
String redactLogText(String value) {
  var result = value.replaceAllMapped(
    _jsonSecrets,
    (match) => '${match[1]}"***"',
  );
  result = result.replaceAllMapped(
    _headers,
    (match) => '${match[1]}${match[2]}***',
  );
  result = result.replaceAllMapped(
    _fields,
    (match) => '${match[1]}${match[2]}***',
  );
  result = result.replaceAllMapped(_codes, (match) => '${match[1]}***');
  result = result.replaceAllMapped(_jsonCodes, (match) => '${match[1]}"***"');
  return result.replaceAllMapped(
    _phones,
    (match) => '${match[0]!.substring(0, 3)}****${match[0]!.substring(7)}',
  );
}
