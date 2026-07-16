import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serializes secure-storage access and skips writes when the exported SDK
/// session has not changed.
class SecureSessionStore {
  SecureSessionStore(this._storage, {required this.key});

  final FlutterSecureStorage _storage;
  final String key;
  Future<void> _tail = Future<void>.value();
  String? _persistedValue;

  Future<String?> read() async {
    await _tail.catchError((_) {});
    final value = await _storage.read(key: key);
    _persistedValue = value;
    return value;
  }

  Future<void> writeIfChanged(String value) {
    late final Future<void> next;
    next = _tail.catchError((_) {}).then((_) async {
      if (_persistedValue == value) return;
      await _storage.write(key: key, value: value);
      _persistedValue = value;
    });
    _tail = next;
    return next;
  }

  Future<void> delete() {
    late final Future<void> next;
    next = _tail.catchError((_) {}).then((_) async {
      await _storage.delete(key: key);
      _persistedValue = null;
    });
    _tail = next;
    return next;
  }
}
