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

abstract class OrderEventsLocalRepository {
  /// Unconditionally upserts [event] for [storeId], stamping the row with
  /// [syncGeneration]. Used for live WebSocket events and manual REST updates.
  Future<Result<void, AppError>> save(
    OrderEvent event, {
    required String storeId,
    required int syncGeneration,
  });

  /// Like [save], but only overwrites the payload when [event] is not older
  /// than the stored row (see [shouldReplaceStoredOrder]). Always updates the
  /// [syncGeneration] stamp — even when the payload is skipped — so that the
  /// sweep step doesn't remove an order that still exists on the server but
  /// was already updated more recently by the live socket.
  Future<Result<void, AppError>> saveIfNewer(
    OrderEvent event, {
    required String storeId,
    required int syncGeneration,
  });

  /// Removes orders for [storeId] whose [syncGeneration] stamp is below
  /// [currentGeneration] (absent from the latest REST sync) and whose
  /// [updatedAt] is before [syncStartedAt] (not written mid-flight by the
  /// WebSocket). Call this after the [saveIfNewer] upsert loop to propagate
  /// server-side deletes to the local DB without hitting any SQLite variable
  /// count limit.
  Future<Result<void, AppError>> sweepStaleOrders({
    required String storeId,
    required int currentGeneration,
    required DateTime syncStartedAt,
  });

  /// Orders for [storeId] not yet cancelled.
  Stream<int> watchPendingCount(String storeId);

  /// All persisted orders for [storeId], most recently updated first.
  Stream<List<OrderEvent>> watchOrders(String storeId);

  /// Deletes every persisted order for [storeId].
  Future<Result<void, AppError>> deleteAll(String storeId);
}

class OrderEventsLocalRepositoryImpl implements OrderEventsLocalRepository {
  const OrderEventsLocalRepositoryImpl(this._dao);

  final OrderEventsDao _dao;

  @override
  Future<Result<void, AppError>> save(
    OrderEvent event, {
    required String storeId,
    required int syncGeneration,
  }) async {
    try {
      // A manual update that sets `status: cancelled` still arrives as an
      // `order.updated` event; normalize it here so `watchPendingCount`
      // (which filters on `eventType != 'cancelled'`) and the reconstructed
      // `OrderEventType` in `watchOrders` both treat it as cancelled.
      final effectiveType = event.type == OrderEventType.cancelled ||
              event.data.status.toLowerCase() == 'cancelled'
          ? OrderEventType.cancelled.name
          : event.type.name;
      await _dao.upsertOrder(
        orderId: event.eventId,
        storeId: storeId,
        eventType: effectiveType,
        payload: jsonEncode(event.data.toJson()),
        syncGeneration: syncGeneration,
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> saveIfNewer(
    OrderEvent event, {
    required String storeId,
    required int syncGeneration,
  }) async {
    try {
      final existingRow = await _dao.getOrder(event.data.id, storeId);
      final existing = existingRow == null
          ? null
          : OrderData.fromJson(jsonDecode(existingRow.payload) as Map<String, dynamic>);
      if (!shouldReplaceStoredOrder(existing: existing, incoming: event.data)) {
        // Payload isn't newer (socket already wrote a more recent update), but
        // the order still exists on the server — bump its generation stamp so
        // the sweep doesn't delete it.
        if (existingRow != null) {
          await _dao.stampSyncGeneration(event.data.id, storeId, syncGeneration);
        }
        return const Success(null);
      }
      return save(event, storeId: storeId, syncGeneration: syncGeneration);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> sweepStaleOrders({
    required String storeId,
    required int currentGeneration,
    required DateTime syncStartedAt,
  }) async {
    try {
      await _dao.sweepStaleOrders(
        storeId: storeId,
        currentGeneration: currentGeneration,
        updatedBefore: syncStartedAt,
      );
      return const Success(null);
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
