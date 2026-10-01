class MusicSdkException implements Exception {
  const MusicSdkException(
    this.message, {
    this.retryable = false,
    this.expired = false,
    this.authenticationRequired = false,
    this.code,
  });
  final String message;
  final bool retryable;
  final bool expired;
  final bool authenticationRequired;
  final int? code;

  @override
  String toString() => message;
}

class StaleSessionException extends MusicSdkException {
  const StaleSessionException() : super('账号已切换，请重试');
}
