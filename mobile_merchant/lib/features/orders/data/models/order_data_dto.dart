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
}
