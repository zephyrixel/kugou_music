import 'dart:async';

import 'package:kgmusic/core/models/account.dart';

/// Shared identity for in-flight work. A generation remains invalid even if
/// the user signs back into the same account.
class AccountSession {
  static const guest = AuthSnapshot(
    authenticated: false,
    fingerprintRegistered: false,
  );
  AuthSnapshot _snapshot = guest;
  int _generation = 0;
  final _expirations = StreamController<void>.broadcast(sync: true);

  AuthSnapshot get snapshot => _snapshot;
  int? get userId => _snapshot.authenticated ? _snapshot.userId : null;
  int get generation => _generation;
  Stream<void> get expirations => _expirations.stream;
  bool isCurrent(int generation) =>
      generation == _generation && !_expirations.isClosed;

  void update(AuthSnapshot snapshot) {
    if (_snapshot.userId != snapshot.userId ||
        _snapshot.authenticated != snapshot.authenticated) {
      _generation++;
    }
    _snapshot = snapshot;
  }

  void invalidate() {
    _generation++;
    _snapshot = guest;
  }

  void expire() {
    if (!_snapshot.authenticated || _expirations.isClosed) return;
    invalidate();
    _expirations.add(null);
  }

  Future<void> dispose() async {
    invalidate();
    await _expirations.close();
  }
}
