import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class AppErrorBus {
  final StreamController<String> _messages = StreamController.broadcast();
  final Map<String, DateTime> _recent = {};

  Stream<String> get messages => _messages.stream;

  void add(String message, {Object? cause, StackTrace? stackTrace}) {
    final now = DateTime.now();
    final previous = _recent[message];
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 8)) {
      return;
    }
    AppLog.warn(
      '应用提示：$message',
      target: 'app.error_bus',
      error: cause,
      stackTrace: stackTrace,
    );
    _recent[message] = now;
    _recent.removeWhere(
      (_, timestamp) => now.difference(timestamp) > const Duration(minutes: 1),
    );
    _messages.add(message);
  }

  Future<void> dispose() => _messages.close();
}

class AppErrorListener extends StatefulWidget {
  const AppErrorListener({
    super.key,
    required this.bus,
    required this.messengerKey,
    required this.child,
  });

  final AppErrorBus bus;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<AppErrorListener> createState() => _AppErrorListenerState();
}

class _AppErrorListenerState extends State<AppErrorListener> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant AppErrorListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bus, widget.bus)) _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = widget.bus.messages.listen((message) {
      if (!mounted) return;
      showAppErrorWithMessenger(widget.messengerKey, message);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
