import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/order_events_table.dart';

part 'order_events_dao.g.dart';

@DriftAccessor(tables: [OrderEventsTable])
class OrderEventsDao extends DatabaseAccessor<AppDatabase> with _$OrderEventsDaoMixin {
  OrderEventsDao(super.db);

  /// Runs [action] inside a single database transaction. Drift buffers the
  /// table-update notifications raised by writes in [action] and dispatches
  /// them once, on commit — so a reactive query like [watchOrders] re-emits
  /// a single time for the whole batch instead of once per row.
  Future<void> runInTransaction(Future<void> Function() action) =>
      transaction(action);

  /// Upserts the latest known state for an order, keyed by [orderId].
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

  /// Count of every persisted order for [storeId] — no status filtering, so
  /// it always equals the length of the [watchOrders] list (and the number of
  /// distinct orders the history endpoint returned). Cancelled/fulfilled
  /// orders are counted too; the badge is "orders on record", not "orders
  /// needing attention".
  Stream<int> watchOrderCount(String storeId) {
    final query = selectOnly(orderEventsTable)
      ..addColumns([orderEventsTable.orderId.count()])
      ..where(orderEventsTable.storeId.equals(storeId));
    return query.map((row) => row.read(orderEventsTable.orderId.count()) ?? 0).watchSingle();
  }

  /// All persisted orders for [storeId], most recently updated first. Backs
  /// the Orders screen list, so it matches [watchOrderCount] — both read
  /// the same on-disk state instead of relying on the in-memory live feed.
  Stream<List<OrderEventsTableData>> watchOrders(String storeId) {
    return (select(orderEventsTable)
          ..where((t) => t.storeId.equals(storeId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Deletes every persisted order for [storeId]. Called at the start of a
  /// history sync (inside the same transaction as the re-insert) so the
  /// local table is rebuilt from the server response — propagating
  /// server-side deletions without any per-row bookkeeping.
  Future<void> deleteOrdersForStore(String storeId) {
    return (delete(orderEventsTable)..where((t) => t.storeId.equals(storeId)))
        .go();
  }
}
