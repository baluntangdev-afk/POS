import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Set when the Cartivo session token is rejected as `invalid_or_expired_token`
/// and the token interceptor's single refresh retry could not recover. The root
/// listener in `main.dart` turns this into a "sign in again" dialog followed by
/// a forced logout.
class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void report() => state = true;

  void clear() => state = false;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(
  SessionExpiredNotifier.new,
);
