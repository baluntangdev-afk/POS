import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/orders_history_api.dart';
import '../use_cases/latest_event_per_order.dart';
import 'order_events_local_repository.dart';

final ordersHistoryRepositoryProvider = Provider<OrdersHistoryRepository>((ref) {
  final api = ref.watch(ordersHistoryApiProvider);
  final localRepository = ref.watch(orderEventsLocalRepositoryProvider);
  return OrdersHistoryRepositoryImpl(api, localRepository);
});

/// Backfills local order history from the REST endpoint.
abstract class OrdersHistoryRepository {
  /// Fetches order history for [kioskId] and merges it into local storage,
  /// with write-if-newer semantics so it can never overwrite an order the
  /// live socket has already updated more recently. Throws on failure
  /// (network error, etc.) — callers decide whether that should be silent
  /// or surfaced to the UI.
  Future<void> syncHistory(String kioskId);
}

class OrdersHistoryRepositoryImpl implements OrdersHistoryRepository {
  const OrdersHistoryRepositoryImpl(this._api, this._localRepository);

  final OrdersHistoryApi _api;
  final OrderEventsLocalRepository _localRepository;

  @override
  Future<void> syncHistory(String kioskId) async {
    final events = await _api.fetchEvents(kioskId);
    final latest = latestEventPerOrder(events);
    for (final event in latest) {
      await _localRepository.saveIfNewer(event, kioskId: kioskId);
    }
  }
}
