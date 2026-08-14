import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../../customer_display_window_argument.dart';
import '../../sales/repositories/product_group_repository.dart';
import '../../sales/repositories/product_repository.dart';
import '../../sales/repositories/store_repository.dart';
import '../../sales/state/ordering_notifier.dart';
import '../entities/customer_display_catalog.dart';
import '../entities/customer_display_snapshot.dart';
import 'customer_display_log.dart';
import 'snapshot_debouncer.dart';

/// How often the cashier engine re-fetches the catalog (store name + every
/// category's products) and pushes it to the customer display. There is no
/// push/websocket infrastructure in the backend today, so this poll is what
/// "real-time" means here — admin edits (price, new product, store name)
/// show up on the display within one interval.
const _catalogPollInterval = Duration(seconds: 15);

/// Runs in the cashier engine. Owns the customer-display window's entire
/// lifecycle: creating it when a second monitor is present, recreating it if
/// it disappears, and pushing the current order state to it. Every method
/// here is best-effort — a failure anywhere in this class must never throw
/// into or block the cashier's own code paths.
class CustomerDisplayHost with ScreenListener {
  CustomerDisplayHost._(this._container);

  final ProviderContainer _container;
  final _debouncer = SnapshotDebouncer();
  final _log = CustomerDisplayLog('customer-display-host.log');

  WindowController? _controller;
  StreamSubscription<void>? _windowsChangedSubscription;
  ProviderSubscription<AsyncValue<OrderingData>>? _orderingSubscription;
  Timer? _retryTimer;
  Timer? _catalogTimer;
  CustomerDisplayCatalog? _lastCatalog;
  bool _disposed = false;

  /// Starts the host for [container], the cashier's own `ProviderContainer`.
  /// No-op (returns null) on anything other than Windows.
  static CustomerDisplayHost? start(ProviderContainer container) {
    if (kIsWeb || !Platform.isWindows) return null;
    final host = CustomerDisplayHost._(container);
    unawaited(host._initialize());
    return host;
  }

  Future<void> _initialize() async {
    screenRetriever.addListener(this);
    _windowsChangedSubscription = onWindowsChanged.listen((_) => unawaited(_reconcileWindow()));
    _orderingSubscription = _container.listen<AsyncValue<OrderingData>>(
      orderingProvider,
      (previous, next) {
        final data = next.value;
        if (data == null) return;
        final justCompleted = data.receipt != null && previous?.value?.receipt == null;
        _debouncer.schedule(() => _pushSnapshot(data, justCompleted: justCompleted));
      },
      fireImmediately: true,
    );
    _catalogTimer = Timer.periodic(_catalogPollInterval, (_) => unawaited(_pollCatalog()));
    unawaited(_pollCatalog());
    await _syncWindowToDisplays();
  }

  Future<void> _pollCatalog() async {
    if (_disposed) return;
    unawaited(_log.write('poll: starting'));
    try {
      final store = await _container.read(storeRepositoryProvider).getCurrent();
      final groups = await _container.read(productGroupRepositoryProvider).getAll();
      unawaited(_log.write('poll: store="${store.legalName}", ${groups.length} groups fetched'));
      final productRepository = _container.read(productRepositoryProvider);

      final categories = <CustomerDisplayCategory>[];
      for (final group in groups) {
        final products = await productRepository.getByGroup(group);
        unawaited(_log.write('poll: group "${group.name}" (id ${group.id}) → ${products.length} products'));
        categories.add(CustomerDisplayCategory.build(group: group, products: products.toList()));
      }

      final catalog = CustomerDisplayCatalog.build(store: store, categories: categories);
      _lastCatalog = catalog;
      unawaited(_log.write('poll: catalog built ok, ${categories.length} categories, controller=${_controller != null}'));
      _pushCatalog(catalog);
    } catch (e, s) {
      unawaited(_log.write('poll: FAILED: $e\n$s'));
    }
  }

  void _pushCatalog(CustomerDisplayCatalog catalog) {
    final controller = _controller;
    if (controller == null) {
      unawaited(_log.write('push: skipped, no display window yet'));
      return;
    }
    unawaited(
      controller
          .invokeMethod('catalogSync', catalog.toTransportMap())
          .then((_) => _log.write('push: catalogSync sent ok'))
          .catchError((Object e) => _log.write('push: catalogSync FAILED: $e')),
    );
  }

  @override
  void onScreenEvent(String eventName) {
    unawaited(_syncWindowToDisplays());
  }

  Future<void> _reconcileWindow() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final all = await WindowController.getAll();
      final stillAlive = all.any((c) => c.windowId == controller.windowId);
      if (!stillAlive) {
        _controller = null;
        await _syncWindowToDisplays();
      }
    } catch (_) {
      // Best-effort — if we can't even ask, leave state as-is for the next
      // onWindowsChanged/onScreenEvent tick to sort out.
    }
  }

  Future<void> _syncWindowToDisplays() async {
    if (_disposed) return;

    List<Display> displays;
    try {
      displays = await screenRetriever.getAllDisplays();
    } catch (_) {
      return;
    }

    if (displays.length < 2) {
      final stale = _controller;
      if (stale != null) {
        _controller = null;
        try {
          await stale.invokeMethod('window_close_request');
        } catch (_) {
          // Already gone or unreachable — nothing further to do.
        }
      }
      return;
    }

    if (_controller != null) return;

    try {
      final controller = await WindowController.create(
        const WindowConfiguration(arguments: customerDisplayWindowArgument),
      );
      await controller.show();
      _controller = controller;
      final data = _container.read(orderingProvider).value;
      if (data != null) {
        _pushSnapshot(data, justCompleted: false);
      }
      final catalog = _lastCatalog;
      if (catalog != null) {
        _pushCatalog(catalog);
      }
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () => unawaited(_syncWindowToDisplays()));
  }

  void _pushSnapshot(OrderingData data, {required bool justCompleted}) {
    final controller = _controller;
    if (controller == null) return;

    final receipt = data.receipt;
    final CustomerDisplaySnapshot snapshot;
    if (justCompleted && receipt != null) {
      snapshot = CustomerDisplayThankYou.fromReceipt(receipt);
    } else if (data.sale.items.isEmpty) {
      snapshot = CustomerDisplayIdle.fromStore(data.store);
    } else {
      snapshot = CustomerDisplayOrdering.fromSale(data.sale);
    }

    unawaited(controller.invokeMethod('sync', snapshot.toTransportMap()).catchError((_) {}));
  }

  void dispose() {
    _disposed = true;
    screenRetriever.removeListener(this);
    unawaited(_windowsChangedSubscription?.cancel());
    _orderingSubscription?.close();
    _retryTimer?.cancel();
    _catalogTimer?.cancel();
    _debouncer.dispose();
  }
}
