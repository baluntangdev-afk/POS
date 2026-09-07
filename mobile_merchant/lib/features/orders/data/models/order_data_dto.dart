import 'order_item_dto.dart';

class OrderDataDto {
  const OrderDataDto({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerEmail,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.merchantId,
    required this.items,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String? customerEmail;
  final String status;
  final double total;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String merchantId;
  final List<OrderItemDto> items;

  factory OrderDataDto.fromJson(Map<String, dynamic> json) => OrderDataDto(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: json['customer_name'] as String?,
        customerEmail: json['customer_email'] as String?,
        status: json['status'] as String,
        total: (json['total'] as num).toDouble(),
        currency: json['currency'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        merchantId: json['merchant_id'] as String,
        items: (json['items'] as List)
            .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Lenient parser for the live WebSocket payload. Only [id] is required
  /// (its absence throws, and the caller treats that as a dropped event);
  /// everything else falls back to a sane default rather than throwing.
  factory OrderDataDto.fromWireJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final updated = DateTime.tryParse(json['updated_at']?.toString() ?? '');
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return OrderDataDto(
      id: json['id'] as String,
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      status: json['status']?.toString() ?? 'unknown',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? '',
      createdAt: created ?? updated ?? epoch,
      updatedAt: updated ?? created ?? epoch,
      merchantId: json['merchant_id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemDto.fromWireJson)
          .toList(),
    );
  }
}
