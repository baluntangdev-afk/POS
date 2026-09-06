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
}
