import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_expired_notifier.dart';
import '../di/injection.dart';
import '../utils/app_logger.dart';

/// Mounted once in `App.builder`. Subscribes to the session-expiry stream and
/// reacts to it.
///
/// STUB: for now it only logs. When the `auth` feature lands, this is where you
/// call `authNotifier.logout()`, navigate to the login route, then
/// `resetNotifying()`.
class SessionExpiredListener extends ConsumerStatefulWidget {
  const SessionExpiredListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionExpiredListener> createState() =>
      _SessionExpiredListenerState();
}

class _SessionExpiredListenerState
    extends ConsumerState<SessionExpiredListener> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    final notifier = getIt<SessionExpiredNotifier>();
    _sub = notifier.onSessionExpired.listen((_) {
      AppLogger.logWarning(
        'SessionExpiredListener: session expired — hook up logout + redirect '
        'here once the auth feature exists.',
      );
      notifier.resetNotifying();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
