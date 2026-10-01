import 'dart:async';

class AppErrorBus {
  final StreamController<String> _messages = StreamController.broadcast();
  final Map<String, DateTime> _recent = {};

  Stream<String> get messages => _messages.stream;

  void add(String message) {
    if (_messages.isClosed) return;
    final now = DateTime.now();
    final previous = _recent[message];
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 8)) {
      return;
    }
    _recent[message] = now;
    _recent.removeWhere(
      (_, timestamp) => now.difference(timestamp) > const Duration(minutes: 1),
    );
    _messages.add(message);
  }

  Future<void> dispose() => _messages.close();
}
