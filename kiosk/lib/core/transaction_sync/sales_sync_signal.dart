import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final salesSyncSignalProvider = Provider<SalesSyncSignal>((ref) {
  final signal = SalesSyncSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

/// Fires whenever a sale/refund/void commits into a syncable state, so the
/// app can push it to the orders service within seconds instead of waiting
/// for the next periodic tick. The kiosk counterpart of the mobile app's
/// `SalesDao.onSyncNeeded` — kiosk sales are committed through our backend's
/// API rather than a local DB, so the committing call sites ping this instead.
class SalesSyncSignal {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}

/// Stream form of [SalesSyncSignal], for `ref.listen` at the app root.
final salesSyncTriggerProvider = StreamProvider<void>((ref) {
  return ref.watch(salesSyncSignalProvider).stream;
});
