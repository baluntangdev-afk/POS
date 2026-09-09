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
  ///
  /// The REST feed is an event *log* — it can carry several events for one
  /// order. They are collapsed here to the latest event per order (highest
  /// `id`, matching `orders_body._deduplicateByOrderId`) so the table holds
  /// one row per order — the invariant [upsertLiveEvent] relies on.
  Future<void> replaceAll(
    String merchantId,
    List<OrderEventDto> events,
  ) async {
    final latestPerOrder = <String, OrderEventDto>{};
    for (final event in events) {
      final existing = latestPerOrder[event.data.id];
      if (existing == null || event.id > existing.id) {
        latestPerOrder[event.data.id] = event;
      }
    }
    final dedupedEvents = latestPerOrder.values.toList();

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

      for (final event in dedupedEvents) {
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
            fulfillmentType: Value(event.data.fulfillmentType.wireValue),
            facilityName: Value(event.data.facilityName),
            districtName: Value(event.data.districtName),
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

  /// Removes the cached event and its line items for [orderId] under
  /// [merchantId] — the local side of an `order.deleted` live event. A no-op
  /// when nothing matches. Runs in a single transaction.
  Future<void> deleteOrder(String merchantId, String orderId) async {
    await transaction(() async {
      final rowIds = await (select(orderEventsTable)
            ..where((t) =>
                t.orderId.equals(orderId) & t.merchantId.equals(merchantId)))
          .map((e) => e.id)
          .get();

      if (rowIds.isEmpty) return;

      await (delete(orderItemsTable)..where((t) => t.eventId.isIn(rowIds)))
          .go();
      await (delete(orderEventsTable)..where((t) => t.id.isIn(rowIds))).go();
    });
  }

  /// Updates the `order_status` column for every event that belongs to [orderId].
  Future<void> updateOrderStatus(String orderId, String newStatus) =>
      (update(orderEventsTable)..where((t) => t.orderId.equals(orderId))).write(
        OrderEventsTableCompanion(orderStatus: Value(newStatus)),
      );

  /// Upserts a single live WebSocket event, keyed by ([merchantId], `orderId`)
  /// — one row per order, latest event wins. On an update the row keeps its
  /// existing `id` (so pagination cursors stay valid); a brand-new order is
  /// inserted with the event's synthesized `id`. The order's line items are
  /// fully replaced. All in one transaction.
  Future<void> upsertLiveEvent(String merchantId, OrderEventDto event) async {
    await transaction(() async {
      // Newest first. Normally 0 or 1 row, but a cache written before
      // [replaceAll] deduped (or an offline session where it never ran) can
      // hold several rows for one order — heal that here instead of letting
      // `getSingleOrNull` throw "Too many elements".
      final matches = await (select(orderEventsTable)
            ..where((t) =>
                t.orderId.equals(event.data.id) &
                t.merchantId.equals(merchantId))
            ..orderBy([(t) => OrderingTerm.desc(t.id)]))
          .get();

      final existing = matches.isEmpty ? null : matches.first;

      if (matches.length > 1) {
        final staleIds = matches.skip(1).map((e) => e.id).toList();
        await (delete(orderItemsTable)..where((t) => t.eventId.isIn(staleIds)))
            .go();
        await (delete(orderEventsTable)..where((t) => t.id.isIn(staleIds))).go();
      }

      final rowId = existing?.id ?? event.id;

      if (existing != null) {
        await (update(orderEventsTable)..where((t) => t.id.equals(rowId))).write(
          OrderEventsTableCompanion(
            eventId: Value(event.eventId),
            eventType: Value(event.eventType),
            receivedAt: Value(event.receivedAt.toIso8601String()),
            customerName: Value(event.data.customerName),
            customerEmail: Value(event.data.customerEmail),
            orderStatus: Value(event.data.status),
            orderTotal: Value(event.data.total),
            currency: Value(event.data.currency),
            orderUpdatedAt: Value(event.data.updatedAt.toIso8601String()),
            fulfillmentType: Value(event.data.fulfillmentType.wireValue),
            facilityName: Value(event.data.facilityName),
            districtName: Value(event.data.districtName),
          ),
        );
        await (delete(orderItemsTable)..where((t) => t.eventId.equals(rowId)))
            .go();
      } else {
        await into(orderEventsTable).insert(
          OrderEventsTableCompanion.insert(
            id: Value(rowId),
            eventId: event.eventId,
            eventType: event.eventType,
            receivedAt: event.receivedAt.toIso8601String(),
            createdAt: event.createdAt.toIso8601String(),
            merchantId: merchantId,
            orderId: event.data.id,
            customerId: event.data.customerId,
            customerName: Value(event.data.customerName),
            customerEmail: Value(event.data.customerEmail),
            orderStatus: event.data.status,
            orderTotal: event.data.total,
            currency: event.data.currency,
            orderCreatedAt: event.data.createdAt.toIso8601String(),
            orderUpdatedAt: event.data.updatedAt.toIso8601String(),
            fulfillmentType: Value(event.data.fulfillmentType.wireValue),
            facilityName: Value(event.data.facilityName),
            districtName: Value(event.data.districtName),
          ),
        );
      }

      for (final item in event.data.items) {
        await into(orderItemsTable).insert(
          OrderItemsTableCompanion.insert(
            eventId: rowId,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            price: item.price,
          ),
        );
      }
    });
  }

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
          fulfillmentType: FulfillmentType.fromWire(e.fulfillmentType),
          facilityName: e.facilityName,
          districtName: e.districtName,
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
