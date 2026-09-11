import '../entities/order_event.dart';

/// Collapses a batch of events (as returned by the REST history endpoint —
/// the full per-event log, not one row per order) down to a single
/// [OrderEvent] per `orderId`: whichever has the latest [OrderData.updatedAt].
///
/// Any order with an `order.deleted` tombstone anywhere in its log is
/// dropped outright rather than timestamp-compared against its other
/// events: a tombstone carries no real `updatedAt` (it defaults to the
/// epoch), so letting it compete on recency would almost always lose to the
/// order's last real update and leave the "deleted" order still present.
List<OrderEvent> latestEventPerOrder(List<OrderEvent> events) {
  final deletedOrderIds = <String>{
    for (final event in events)
      if (event.type == OrderEventType.deleted) event.data.id,
  };

  final byOrderId = <String, OrderEvent>{};
  for (final event in events) {
    if (deletedOrderIds.contains(event.data.id)) continue;
    final current = byOrderId[event.data.id];
    if (current == null || !event.data.updatedAt.isBefore(current.data.updatedAt)) {
      byOrderId[event.data.id] = event;
    }
  }
  return byOrderId.values.toList();
}
