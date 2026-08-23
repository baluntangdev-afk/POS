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
    required String storeId,
    required String eventType,
    required String payload,
  }) {
    return into(orderEventsTable).insertOnConflictUpdate(
      OrderEventsTableCompanion.insert(
        orderId: orderId,
        storeId: storeId,
        eventType: eventType,
        payload: payload,
      ),
    );
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
}
