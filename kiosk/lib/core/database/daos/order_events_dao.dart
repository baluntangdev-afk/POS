import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/order_events_table.dart';

part 'order_events_dao.g.dart';

@DriftAccessor(tables: [OrderEventsTable])
class OrderEventsDao extends DatabaseAccessor<AppDatabase> with _$OrderEventsDaoMixin {
  OrderEventsDao(super.db);

  /// Upserts the latest known state for an order, keyed by [orderId] — a
  /// later `updated`/`cancelled` event overwrites the row `created` made.
  Future<void> upsertOrder({
    required String orderId,
    required String kioskId,
    required String eventType,
    required String payload,
  }) {
    return into(orderEventsTable).insertOnConflictUpdate(
      OrderEventsTableCompanion.insert(
        orderId: orderId,
        kioskId: kioskId,
        eventType: eventType,
        payload: payload,
      ),
    );
  }

  /// The currently stored row for [orderId] within [kioskId], if any — used
  /// to decide whether a REST-sourced event is newer than what's on disk.
  Future<OrderEventsTableData?> getOrder(String orderId, String kioskId) {
    return (select(orderEventsTable)
          ..where((t) => t.orderId.equals(orderId) & t.kioskId.equals(kioskId)))
        .getSingleOrNull();
  }

  /// Orders for [kioskId] whose latest known event isn't a cancellation.
  Stream<int> watchPendingCount(String kioskId) {
    final query =
        selectOnly(orderEventsTable)
          ..addColumns([orderEventsTable.orderId.count()])
          ..where(
            orderEventsTable.kioskId.equals(kioskId) &
                orderEventsTable.eventType.equals('cancelled').not(),
          );
    return query.map((row) => row.read(orderEventsTable.orderId.count()) ?? 0).watchSingle();
  }

  /// All persisted orders for [kioskId], most recently updated first. Backs
  /// the Orders screen list, so it matches [watchPendingCount] — both read
  /// the same on-disk state instead of the in-memory live-feed events.
  Stream<List<OrderEventsTableData>> watchOrders(String kioskId) {
    return (select(orderEventsTable)
          ..where((t) => t.kioskId.equals(kioskId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Deletes every persisted order for [kioskId].
  Future<void> deleteAll(String kioskId) {
    return (delete(orderEventsTable)..where((t) => t.kioskId.equals(kioskId))).go();
  }
}
