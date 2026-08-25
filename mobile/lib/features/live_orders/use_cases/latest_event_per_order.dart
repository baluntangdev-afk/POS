import '../entities/order_event.dart';

/// Collapses a batch of events (as returned by the REST history endpoint —
/// the full per-event log, not one row per order) down to a single
/// [OrderEvent] per `orderId`: whichever has the latest [OrderData.updatedAt].
List<OrderEvent> latestEventPerOrder(List<OrderEvent> events) {
  final byOrderId = <String, OrderEvent>{};
  for (final event in events) {
    final current = byOrderId[event.data.id];
    if (current == null || !event.data.updatedAt.isBefore(current.data.updatedAt)) {
      byOrderId[event.data.id] = event;
    }
  }
  return byOrderId.values.toList();
}
