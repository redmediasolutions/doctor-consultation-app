import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';

/// Shared plumbing for all view models: safe notify after dispose,
/// periodic polling that pauses while a request is in flight, and error text.
abstract class BaseViewModel extends ChangeNotifier {
  bool _disposed = false;
  final List<Timer> _timers = [];

  bool get isDisposed => _disposed;

  /// Turns any error into something presentable.
  String describeError(Object e) {
    if (e is ApiException) return e.message;
    if (e is StateError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// Runs [task] now and then every [interval] until the view model is disposed.
  /// Overlapping runs are skipped.
  Timer poll(Duration interval, Future<void> Function() task, {bool immediately = true}) {
    var running = false;
    Future<void> run() async {
      if (running || _disposed) return;
      running = true;
      try {
        await task();
      } catch (e) {
        debugPrint('poll error: $e');
      } finally {
        running = false;
      }
    }

    if (immediately) run();
    final t = Timer.periodic(interval, (_) => run());
    _timers.add(t);
    return t;
  }

  void cancelTimer(Timer? t) {
    if (t == null) return;
    t.cancel();
    _timers.remove(t);
  }

  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
