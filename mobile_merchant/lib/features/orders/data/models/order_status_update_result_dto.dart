import 'order_event_dto.dart';

/// Response body of `PATCH /merchant/orders/{orderId}`.
///
/// ```json
/// {
///   "status": "processed",
///   "event_id": "evt_…",
///   "event": { "event_id": …, "event_type": "order.updated", "data": { … } }
/// }
/// ```
///
/// [event] is the canonical `order.updated` envelope the backend also
/// broadcasts on the live feed — parsed with the same lenient
/// [OrderEventDto.fromWireJson] path and left `null` if it can't be read.
class OrderStatusUpdateResultDto {
  const OrderStatusUpdateResultDto({
    required this.status,
    required this.eventId,
    required this.event,
  });

  final String status;
  final String? eventId;
  final OrderEventDto? event;

  factory OrderStatusUpdateResultDto.fromJson(Map<String, dynamic> json) {
    final rawEvent = json['event'];
    return OrderStatusUpdateResultDto(
      status: json['status']?.toString() ?? 'unknown',
      eventId: json['event_id']?.toString(),
      event: rawEvent is Map<String, dynamic>
          ? OrderEventDto.fromWireJson(rawEvent)
          : null,
    );
  }
}
