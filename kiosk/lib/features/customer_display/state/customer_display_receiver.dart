import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../entities/customer_display_catalog.dart';
import '../entities/customer_display_snapshot.dart';
import 'customer_display_log.dart';

final customerDisplaySnapshotProvider =
    NotifierProvider<CustomerDisplaySnapshotNotifier, CustomerDisplaySnapshot>(
  CustomerDisplaySnapshotNotifier.new,
);

class CustomerDisplaySnapshotNotifier extends Notifier<CustomerDisplaySnapshot> {
  @override
  CustomerDisplaySnapshot build() => const CustomerDisplayIdle(storeName: '');

  void apply(CustomerDisplaySnapshot snapshot) {
    state = snapshot;
  }
}

/// The full menu, refreshed roughly every 15s by [CustomerDisplayHost] —
/// null until the first `catalogSync` push arrives.
final customerDisplayCatalogProvider =
    NotifierProvider<CustomerDisplayCatalogNotifier, CustomerDisplayCatalog?>(
  CustomerDisplayCatalogNotifier.new,
);

class CustomerDisplayCatalogNotifier extends Notifier<CustomerDisplayCatalog?> {
  @override
  CustomerDisplayCatalog? build() => null;

  void apply(CustomerDisplayCatalog catalog) {
    state = catalog;
  }
}

/// Runs inside the customer-display engine. Receives snapshots pushed by
/// [CustomerDisplayHost] (running in the cashier engine) and writes them into
/// [customerDisplaySnapshotProvider]. A thank-you snapshot is shown for 5
/// seconds and then this reverts to the last known idle snapshot locally,
/// without waiting for another push from the host. Also handles
/// `window_close_request`, sent by the host when the monitor count drops
/// back to 1 — this window closes itself via `window_manager` (which is
/// engine-scoped, so this call only ever affects this window).
class CustomerDisplayReceiver {
  CustomerDisplayReceiver(this._container);

  final ProviderContainer _container;
  final _log = CustomerDisplayLog('customer-display-receiver.log');
  CustomerDisplayIdle _lastKnownIdle = const CustomerDisplayIdle(storeName: '');
  Timer? _thankYouTimer;

  void attach(WindowController windowController) {
    unawaited(_log.write('attach: window method handler registered'));
    windowController.setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'sync':
          try {
            _apply(decodeCustomerDisplaySnapshot(call.arguments));
          } catch (e, s) {
            unawaited(_log.write('recv: sync DECODE FAILED: $e\n$s'));
          }
        case 'catalogSync':
          unawaited(_log.write('recv: catalogSync received'));
          try {
            final catalog = CustomerDisplayCatalog.fromTransportMap(call.arguments);
            unawaited(_log.write('recv: decoded ok, ${catalog.categories.length} categories'));
            _container.read(customerDisplayCatalogProvider.notifier).apply(catalog);
          } catch (e, s) {
            unawaited(_log.write('recv: catalogSync DECODE FAILED: $e\n$s'));
          }
        case 'window_close_request':
          await windowManager.destroy();
      }
      return null;
    });
  }

  void _apply(CustomerDisplaySnapshot snapshot) {
    _thankYouTimer?.cancel();

    if (snapshot case final CustomerDisplayIdle idle) {
      _lastKnownIdle = idle;
    }

    _container.read(customerDisplaySnapshotProvider.notifier).apply(snapshot);

    if (snapshot is CustomerDisplayThankYou) {
      _thankYouTimer = Timer(const Duration(seconds: 5), () {
        _container.read(customerDisplaySnapshotProvider.notifier).apply(_lastKnownIdle);
      });
    }
  }

  void dispose() {
    _thankYouTimer?.cancel();
  }
}
