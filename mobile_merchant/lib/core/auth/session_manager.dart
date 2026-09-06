import 'dart:async';

import 'package:injectable/injectable.dart';

import '../utils/app_logger.dart';
import 'session_expired_notifier.dart';

/// Broadcast-stream implementation of [SessionExpiredNotifier] that dedupes
/// repeated 401s until [resetNotifying] is called.
@LazySingleton(as: SessionExpiredNotifier)
class SessionManager implements SessionExpiredNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();
  bool _notifying = false;

  @override
  Stream<void> get onSessionExpired => _controller.stream;

  @override
  void signalExpired() {
    if (_notifying) return;
    _notifying = true;
    AppLogger.logWarning('SessionManager: session expired, signalling logout.');
    _controller.add(null);
  }

  @override
  void resetNotifying() => _notifying = false;

  @override
  @disposeMethod
  void dispose() => _controller.close();
}
