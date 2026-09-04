import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../use_cases/device_token_error.dart';

/// The latest live-orders device-token failure: the classified [reason] plus
/// the [message] to toast. Mirrors [WebhookAuthFailure].
typedef DeviceTokenFailure = ({DeviceTokenError reason, String message});

/// Surfaces the most recent `POST /devices/token` failure so the UI can toast
/// it. [OrdersFeedNotifier] reports failures here from its pre-connect step; a
/// root-level `ref.listen` in `main.dart` shows the toast.
///
/// Holding only the latest value means a stuck reconnect loop that keeps
/// failing with the same reason toasts once, not on every retry.
class DeviceTokenStatusNotifier extends Notifier<DeviceTokenFailure?> {
  @override
  DeviceTokenFailure? build() => null;

  /// Records a token failure. A no-op if it matches the current value, so an
  /// unchanged failure doesn't re-trigger listeners.
  void reportFailure(DeviceTokenError reason, String message) {
    final failure = (reason: reason, message: message);
    if (state != failure) state = failure;
  }

  /// Clears the last failure after a token mint succeeds, so a later failure
  /// — even the same reason — toasts again.
  void clear() {
    if (state != null) state = null;
  }
}

final deviceTokenStatusProvider =
    NotifierProvider<DeviceTokenStatusNotifier, DeviceTokenFailure?>(
      DeviceTokenStatusNotifier.new,
    );
