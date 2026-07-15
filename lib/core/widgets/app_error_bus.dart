import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class AppErrorBus {
  final StreamController<Object> _errors = StreamController.broadcast();
  final Map<String, DateTime> _recent = {};

  Stream<Object> get errors => _errors.stream;

  void add(Object error) {
    final message = error.toString();
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
    _errors.add(error);
  }

  Future<void> dispose() => _errors.close();
}

class AppErrorListener extends StatefulWidget {
  const AppErrorListener({super.key, required this.bus, required this.child});

  final AppErrorBus bus;
  final Widget child;

  @override
  State<AppErrorListener> createState() => _AppErrorListenerState();
}

class _AppErrorListenerState extends State<AppErrorListener> {
  StreamSubscription<Object>? _subscription;

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
    _subscription = widget.bus.errors.listen((error) {
      if (mounted) showAppError(context, error);
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
