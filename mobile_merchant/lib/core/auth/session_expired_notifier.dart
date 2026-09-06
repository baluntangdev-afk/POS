/// Contract for signalling that the session has expired (a 401 slipped past the
/// auth interceptor). Implemented by [SessionManager] in the core layer and
/// listened to once at the widget-tree root.
abstract interface class SessionExpiredNotifier {
  /// Fires once per expiry episode; deduped until [resetNotifying] is called.
  Stream<void> get onSessionExpired;

  /// Called by the auth interceptor when a 401 is observed.
  void signalExpired();

  /// Called by the listener once it has finished logging the user out.
  void resetNotifying();

  /// Releases the underlying stream. Invoked by the DI container on scope
  /// teardown (registered via `@disposeMethod` on the implementation).
  void dispose();
}
