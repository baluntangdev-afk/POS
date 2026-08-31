import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/order_events_table.dart';

part 'order_events_dao.g.dart';

@DriftAccessor(tables: [OrderEventsTable])
class OrderEventsDao extends DatabaseAccessor<AppDatabase> with _$OrderEventsDaoMixin {
  OrderEventsDao(super.db);

  /// Upserts the latest known state for an order, keyed by [orderId]. Stamps
  /// the row with [syncGeneration] so the sweep step knows which sync cycle
  /// last confirmed this order still exists on the server.
  Future<void> upsertOrder({
    required String orderId,
    required String storeId,
    required String eventType,
    required String payload,
    required int syncGeneration,
  }) {
    return into(orderEventsTable).insertOnConflictUpdate(
      OrderEventsTableCompanion.insert(
        orderId: orderId,
        storeId: storeId,
        eventType: eventType,
        payload: payload,
        syncGeneration: Value(syncGeneration),
      ),
    );
  }

  /// Updates only the [syncGeneration] stamp on an existing row, leaving
  /// payload and timestamps untouched. Called by [saveIfNewer] when the
  /// stored row is already newer than the REST response — we still want to
  /// mark the order as "seen this sync" so the sweep doesn't remove it.
  Future<void> stampSyncGeneration(
    String orderId,
    String storeId,
    int syncGeneration,
  ) {
    return (update(orderEventsTable)
          ..where((t) => t.orderId.equals(orderId) & t.storeId.equals(storeId)))
        .write(OrderEventsTableCompanion(syncGeneration: Value(syncGeneration)));
  }

  /// The currently stored row for [orderId] within [storeId], if any — used
  /// to decide whether a REST-sourced event is newer than what's on disk.
  Future<OrderEventsTableData?> getOrder(String orderId, String storeId) {
    return (select(orderEventsTable)
          ..where((t) => t.orderId.equals(orderId) & t.storeId.equals(storeId)))
        .getSingleOrNull();
  }

  /// Orders for [storeId] whose latest known event isn't a cancellation.
  Stream<int> watchPendingCount(String storeId) {
    final query = selectOnly(orderEventsTable)
      ..addColumns([orderEventsTable.orderId.count()])
      ..where(
        orderEventsTable.storeId.equals(storeId) &
            orderEventsTable.eventType.equals('cancelled').not(),
      );
    return query.map((row) => row.read(orderEventsTable.orderId.count()) ?? 0).watchSingle();
  }

  /// All persisted orders for [storeId], most recently updated first. Backs
  /// the Orders screen list, so it matches [watchPendingCount] — both read
  /// the same on-disk state instead of relying on the in-memory live feed.
  Stream<List<OrderEventsTableData>> watchOrders(String storeId) {
    return (select(orderEventsTable)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Deletes every persisted order for [storeId].
  Future<void> deleteAll(String storeId) {
    return (delete(orderEventsTable)..where((t) => t.storeId.equals(storeId))).go();
  }

  /// Deletes stale orders: rows for [storeId] whose [syncGeneration] is below
  /// [currentGeneration] (not seen in the latest sync) AND whose [updatedAt]
  /// is before [updatedBefore] (not written by a live WebSocket event that
  /// arrived while the REST request was in flight).
  Future<void> sweepStaleOrders({
    required String storeId,
    required int currentGeneration,
    required DateTime updatedBefore,
  }) {
    return (delete(orderEventsTable)
          ..where(
            (t) =>
                t.storeId.equals(storeId) &
                t.syncGeneration.isSmallerThanValue(currentGeneration) &
                t.updatedAt.isSmallerThanValue(updatedBefore),
          ))
        .go();
  }
}
