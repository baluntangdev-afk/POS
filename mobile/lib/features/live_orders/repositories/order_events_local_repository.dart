import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/daos/order_events_dao.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/result/result.dart';
import '../entities/order_event.dart';

final orderEventsLocalRepositoryProvider = Provider<OrderEventsLocalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return OrderEventsLocalRepositoryImpl(db.orderEventsDao);
});

abstract class OrderEventsLocalRepository {
  /// Runs [action] in one database transaction so the reactive queries
  /// backing the Orders screen re-emit once (on commit) rather than after
  /// every individual write in [action].
  Future<void> runInTransaction(Future<void> Function() action);

  /// Upserts [event] for [storeId]. Used for live WebSocket events, manual
  /// REST updates, and the history-sync re-insert.
  Future<Result<void, AppError>> save(
    OrderEvent event, {
    required String storeId,
  });

  /// Deletes every persisted order for [storeId]. Called at the start of a
  /// history sync, inside the same transaction as the re-insert, so the
  /// local table is rebuilt from the server response.
  Future<Result<void, AppError>> deleteOrdersForStore(String storeId);

  /// Count of every persisted order for [storeId] — matches the length of
  /// [watchOrders]. No status filtering.
  Stream<int> watchOrderCount(String storeId);

  /// All persisted orders for [storeId], most recently updated first.
  Stream<List<OrderEvent>> watchOrders(String storeId);
}

class OrderEventsLocalRepositoryImpl implements OrderEventsLocalRepository {
  const OrderEventsLocalRepositoryImpl(this._dao);

  final OrderEventsDao _dao;

  @override
  Future<void> runInTransaction(Future<void> Function() action) =>
      _dao.runInTransaction(action);

  @override
  Future<Result<void, AppError>> save(
    OrderEvent event, {
    required String storeId,
  }) async {
    try {
      // A manual update that sets `status: cancelled` still arrives as an
      // `order.updated` event; normalize it here so the `OrderEventType`
      // reconstructed in `watchOrders` is `cancelled` and the card renders
      // with the cancelled badge / no cancel action.
      final effectiveType = event.type == OrderEventType.cancelled ||
              event.data.status.toLowerCase() == 'cancelled'
          ? OrderEventType.cancelled.name
          : event.type.name;
      // Keyed by the order id (one row per order — later events overwrite the
      // row `created` made), NOT the per-event id. `watchOrders` identifies
      // rows the same way.
      await _dao.upsertOrder(
        orderId: event.data.id,
        storeId: storeId,
        eventType: effectiveType,
        payload: jsonEncode(event.data.toJson()),
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteOrdersForStore(String storeId) async {
    try {
      await _dao.deleteOrdersForStore(storeId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Stream<int> watchOrderCount(String storeId) => _dao.watchOrderCount(storeId);

  @override
  Stream<List<OrderEvent>> watchOrders(String storeId) {
    return _dao.watchOrders(storeId).map(
          (rows) => rows
              .map(
                (row) => OrderEvent(
                  eventId: row.orderId,
                  type: OrderEventType.values.byName(row.eventType),
                  data: OrderData.fromJson(jsonDecode(row.payload) as Map<String, dynamic>),
                ),
              )
              .toList(),
        );
  }
}
