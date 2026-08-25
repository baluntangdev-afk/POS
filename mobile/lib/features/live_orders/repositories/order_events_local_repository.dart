import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/daos/order_events_dao.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/result/result.dart';
import '../entities/order_event.dart';
import '../use_cases/should_replace_stored_order.dart';

final orderEventsLocalRepositoryProvider = Provider<OrderEventsLocalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return OrderEventsLocalRepositoryImpl(db.orderEventsDao);
});

/// Local (per-store) persistence of each order's latest known state, backing
/// the pending-orders badge on the Orders tile. Not a source of truth for
/// order data — that's still the in-memory [OrdersFeedState] / a future REST
/// order history.
abstract class OrderEventsLocalRepository {
  Future<Result<void, AppError>> save(OrderEvent event, {required String storeId});

  /// Like [save], but only overwrites the stored row if [event] isn't older
  /// than what's already there (see [shouldReplaceStoredOrder]) — or there's
  /// no stored row yet. Used for REST-sourced history, so a backfill can
  /// never clobber a more recent update the live socket already wrote.
  Future<Result<void, AppError>> saveIfNewer(OrderEvent event, {required String storeId});

  /// Orders for [storeId] not yet cancelled.
  Stream<int> watchPendingCount(String storeId);

  /// All persisted orders for [storeId], most recently updated first. Same
  /// underlying data as [watchPendingCount] — use this wherever the list
  /// needs to match what the badge counts.
  Stream<List<OrderEvent>> watchOrders(String storeId);

  /// Deletes every persisted order for [storeId].
  Future<Result<void, AppError>> deleteAll(String storeId);
}

class OrderEventsLocalRepositoryImpl implements OrderEventsLocalRepository {
  const OrderEventsLocalRepositoryImpl(this._dao);

  final OrderEventsDao _dao;

  @override
  Future<Result<void, AppError>> save(OrderEvent event, {required String storeId}) async {
    try {
      await _dao.upsertOrder(
        orderId: event.data.id,
        storeId: storeId,
        eventType: event.type.name,
        payload: jsonEncode(event.data.toJson()),
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> saveIfNewer(OrderEvent event, {required String storeId}) async {
    try {
      final existingRow = await _dao.getOrder(event.data.id, storeId);
      final existing = existingRow == null
          ? null
          : OrderData.fromJson(jsonDecode(existingRow.payload) as Map<String, dynamic>);
      if (!shouldReplaceStoredOrder(existing: existing, incoming: event.data)) {
        return const Success(null);
      }
      return save(event, storeId: storeId);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Stream<int> watchPendingCount(String storeId) => _dao.watchPendingCount(storeId);

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

  @override
  Future<Result<void, AppError>> deleteAll(String storeId) async {
    try {
      await _dao.deleteAll(storeId);
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
