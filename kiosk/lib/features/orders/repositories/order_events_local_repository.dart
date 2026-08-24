import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/order_events_dao.dart';
import '../entities/order_event.dart';
import '../use_cases/should_replace_stored_order.dart';

final orderEventsLocalRepositoryProvider = Provider<OrderEventsLocalRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OrderEventsLocalRepositoryImpl(db.orderEventsDao);
});

/// Local (per-kiosk) persistence of each order's latest known state, backing
/// the pending-orders badge on the menu. Not a source of truth for order
/// data — that's still the REST order history / [OrdersFeedState] in memory.
abstract class OrderEventsLocalRepository {
  Future<void> save(OrderEvent event, {required String kioskId});

  /// Like [save], but only overwrites the stored row if [event] isn't older
  /// than what's already there (see [shouldReplaceStoredOrder]) — or there's
  /// no stored row yet. Used for REST-sourced history, so a backfill can
  /// never clobber a more recent update the live socket already wrote.
  Future<void> saveIfNewer(OrderEvent event, {required String kioskId});

  /// Orders for [kioskId] not yet cancelled.
  Stream<int> watchPendingCount(String kioskId);

  /// All persisted orders for [kioskId], most recently updated first. Same
  /// underlying data as [watchPendingCount] — use this wherever the list
  /// needs to match what the badge counts.
  Stream<List<OrderEvent>> watchOrders(String kioskId);

  /// Deletes every persisted order for [kioskId].
  Future<void> deleteAll(String kioskId);
}

class OrderEventsLocalRepositoryImpl implements OrderEventsLocalRepository {
  const OrderEventsLocalRepositoryImpl(this._dao);

  final OrderEventsDao _dao;

  @override
  Future<void> save(OrderEvent event, {required String kioskId}) {
    return _dao.upsertOrder(
      orderId: event.data.id,
      kioskId: kioskId,
      eventType: event.type.name,
      payload: event.data.toJson(),
    );
  }

  @override
  Future<void> saveIfNewer(OrderEvent event, {required String kioskId}) async {
    final existingRow = await _dao.getOrder(event.data.id, kioskId);
    final existing = existingRow == null ? null : OrderData.fromJson(existingRow.payload);
    if (!shouldReplaceStoredOrder(existing: existing, incoming: event.data)) return;
    await save(event, kioskId: kioskId);
  }

  @override
  Stream<int> watchPendingCount(String kioskId) => _dao.watchPendingCount(kioskId);

  @override
  Stream<List<OrderEvent>> watchOrders(String kioskId) {
    return _dao.watchOrders(kioskId).map(
      (rows) => rows
          .map(
            (row) => OrderEvent(
              eventId: row.orderId,
              type: OrderEventType.values.byName(row.eventType),
              data: OrderData.fromJson(row.payload),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> deleteAll(String kioskId) => _dao.deleteAll(kioskId);
}
