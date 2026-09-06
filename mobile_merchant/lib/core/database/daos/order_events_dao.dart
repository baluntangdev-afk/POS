import 'package:drift/drift.dart';

import '../../../features/orders/data/models/order_data_dto.dart';
import '../../../features/orders/data/models/order_event_dto.dart';
import '../../../features/orders/data/models/order_item_dto.dart';
import '../app_database.dart';
import '../tables/order_events_table.dart';
import '../tables/order_items_table.dart';

part 'order_events_dao.g.dart';

@DriftAccessor(tables: [OrderEventsTable, OrderItemsTable])
class OrderEventsDao extends DatabaseAccessor<AppDatabase>
    with _$OrderEventsDaoMixin {
  OrderEventsDao(super.db);

  /// Returns all cached events for [merchantId], newest first, with their
  /// items joined in Dart (two queries — avoids a cross-join explosion).
  Future<List<OrderEventDto>> getEvents(String merchantId) async {
    final events = await (select(orderEventsTable)
          ..where((t) => t.merchantId.equals(merchantId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();

    if (events.isEmpty) return [];

    final eventIds = events.map((e) => e.id).toList();
    final items = await (select(orderItemsTable)
          ..where((t) => t.eventId.isIn(eventIds)))
        .get();

    final itemsByEventId = <int, List<OrderItemsTableData>>{};
    for (final item in items) {
      itemsByEventId.putIfAbsent(item.eventId, () => []).add(item);
    }

    return events
        .map((e) => _toDto(e, itemsByEventId[e.id] ?? []))
        .toList();
  }

  /// Replaces all cached events for [merchantId] with [events] in a single
  /// transaction. Passing an empty list clears the cache for that merchant.
  Future<void> replaceAll(
    String merchantId,
    List<OrderEventDto> events,
  ) async {
    await transaction(() async {
      // Delete items first (FK child), then the parent events.
      final existingIds = await (select(orderEventsTable)
            ..where((t) => t.merchantId.equals(merchantId)))
          .map((e) => e.id)
          .get();

      if (existingIds.isNotEmpty) {
        await (delete(orderItemsTable)
              ..where((t) => t.eventId.isIn(existingIds)))
            .go();
      }

      await (delete(orderEventsTable)
            ..where((t) => t.merchantId.equals(merchantId)))
          .go();

      for (final event in events) {
        await into(orderEventsTable).insert(
          OrderEventsTableCompanion.insert(
            id: Value(event.id),
            eventId: event.eventId,
            eventType: event.eventType,
            receivedAt: event.receivedAt.toIso8601String(),
            createdAt: event.createdAt.toIso8601String(),
            merchantId: event.data.merchantId,
            orderId: event.data.id,
            customerId: event.data.customerId,
            customerName: Value(event.data.customerName),
            customerEmail: Value(event.data.customerEmail),
            orderStatus: event.data.status,
            orderTotal: event.data.total,
            currency: event.data.currency,
            orderCreatedAt: event.data.createdAt.toIso8601String(),
            orderUpdatedAt: event.data.updatedAt.toIso8601String(),
          ),
        );

        for (final item in event.data.items) {
          await into(orderItemsTable).insert(
            OrderItemsTableCompanion.insert(
              eventId: event.id,
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              price: item.price,
            ),
          );
        }
      }
    });
  }

  /// Updates the `order_status` column for every event that belongs to [orderId].
  Future<void> updateOrderStatus(String orderId, String newStatus) =>
      (update(orderEventsTable)..where((t) => t.orderId.equals(orderId))).write(
        OrderEventsTableCompanion(orderStatus: Value(newStatus)),
      );

  // ---------------------------------------------------------------------------

  OrderEventDto _toDto(
    OrderEventsTableData e,
    List<OrderItemsTableData> items,
  ) =>
      OrderEventDto(
        id: e.id,
        receivedAt: DateTime.parse(e.receivedAt),
        eventId: e.eventId,
        eventType: e.eventType,
        createdAt: DateTime.parse(e.createdAt),
        data: OrderDataDto(
          id: e.orderId,
          customerId: e.customerId,
          customerName: e.customerName,
          customerEmail: e.customerEmail,
          status: e.orderStatus,
          total: e.orderTotal,
          currency: e.currency,
          createdAt: DateTime.parse(e.orderCreatedAt),
          updatedAt: DateTime.parse(e.orderUpdatedAt),
          merchantId: e.merchantId,
          items: items
              .map(
                (i) => OrderItemDto(
                  productId: i.productId,
                  productName: i.productName,
                  quantity: i.quantity,
                  price: i.price,
                ),
              )
              .toList(),
        ),
      );
}
