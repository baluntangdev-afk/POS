import 'dart:async';

class SnapshotDebouncer {
  SnapshotDebouncer({this.delay = const Duration(milliseconds: 16)});

  final Duration delay;
  Timer? _timer;

  void schedule(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
