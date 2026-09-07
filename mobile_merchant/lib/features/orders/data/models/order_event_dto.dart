import 'order_data_dto.dart';

class OrderEventDto {
  const OrderEventDto({
    required this.id,
    required this.receivedAt,
    required this.eventId,
    required this.eventType,
    required this.createdAt,
    required this.data,
  });

  final int id;
  final DateTime receivedAt;
  final String eventId;
  final String eventType;
  final DateTime createdAt;
  final OrderDataDto data;

  factory OrderEventDto.fromJson(Map<String, dynamic> json) => OrderEventDto(
        id: json['id'] as int,
        receivedAt: DateTime.parse(json['received_at'] as String),
        eventId: json['event_id'] as String,
        eventType: json['event_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        data: OrderDataDto.fromJson(json['data'] as Map<String, dynamic>),
      );

  /// Parses one frame off the live WebSocket feed. The WS envelope is
  /// `{event_id, event_type, data}` — it lacks the `id` / `received_at` /
  /// `created_at` wrapper the REST payload carries, so those are synthesized.
  /// Returns `null` (never throws) for an unrecognized event type, a missing
  /// `event_id`, or a malformed `data` object.
  static OrderEventDto? fromWireJson(Map<String, dynamic> json) {
    try {
      final eventType = json['event_type'] as String?;
      if (eventType == null || !eventType.startsWith('order.')) return null;

      final eventId = json['event_id'] as String?;
      if (eventId == null || eventId.isEmpty) return null;

      final rawData = json['data'];
      if (rawData is! Map<String, dynamic>) return null;

      final now = DateTime.now();
      return OrderEventDto(
        id: now.microsecondsSinceEpoch,
        receivedAt: now,
        eventId: eventId,
        eventType: eventType,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? now,
        data: OrderDataDto.fromWireJson(rawData),
      );
    } catch (_) {
      return null;
    }
  }
}
