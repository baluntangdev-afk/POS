import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../use_cases/webhook_auth_error.dart';

/// The latest orders-service auth failure: the classified [reason] plus the
/// [message] to toast (the backend's own words when it sent them, otherwise
/// the mapped copy for [reason]).
typedef WebhookAuthFailure = ({WebhookAuthError reason, String message});

/// Surfaces the most recent orders-service authentication failure (a failed
/// `POST /auth/token`) so the UI can toast it. The state notifiers that mint
/// tokens ([OrdersFeedNotifier], [StoreInfoNotifier]) report failures here;
/// a root-level `ref.listen` in `main.dart` shows the toast.
///
/// Holding only the latest value means a stuck reconnect loop that keeps
/// failing with the same reason toasts once, not on every retry.
class WebhookAuthStatusNotifier extends Notifier<WebhookAuthFailure?> {
  @override
  WebhookAuthFailure? build() => null;

  /// Records a token failure. A no-op if it matches the current value, so an
  /// unchanged failure doesn't re-trigger listeners.
  void reportFailure(WebhookAuthError reason, String message) {
    final failure = (reason: reason, message: message);
    if (state != failure) state = failure;
  }

  /// Clears the last failure after a token mint succeeds, so a later failure
  /// — even the same reason — toasts again.
  void clear() {
    if (state != null) state = null;
  }
}

final webhookAuthStatusProvider =
    NotifierProvider<WebhookAuthStatusNotifier, WebhookAuthFailure?>(
      WebhookAuthStatusNotifier.new,
    );
