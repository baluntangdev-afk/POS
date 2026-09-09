import 'order_item_dto.dart';

/// How an order is handed to the customer. Mirrors the webhook's
/// `fulfillment_type`. `on_site` orders carry [OrderDataDto.facilityName];
/// `pickup` / `delivery` never do.
enum FulfillmentType {
  onSite,
  pickup,
  delivery,
  other;

  /// Lenient on purpose — an unrecognized value (the webhook sandbox has been
  /// observed sending `"TEST"`) falls back to [other] instead of throwing.
  static FulfillmentType fromWire(String? value) {
    switch (value) {
      case 'on_site':
        return FulfillmentType.onSite;
      case 'pickup':
        return FulfillmentType.pickup;
      case 'delivery':
        return FulfillmentType.delivery;
      default:
        return FulfillmentType.other;
    }
  }

  /// Inverse of [fromWire] — used only when re-serializing for the local
  /// cache, so a persisted-then-reloaded order round-trips through the same
  /// value rather than drifting to [other].
  String get wireValue => switch (this) {
        FulfillmentType.onSite => 'on_site',
        FulfillmentType.pickup => 'pickup',
        FulfillmentType.delivery => 'delivery',
        FulfillmentType.other => 'other',
      };
}

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
    this.fulfillmentType = FulfillmentType.other,
    this.facilityName,
    this.districtName,
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
  final FulfillmentType fulfillmentType;
  final String? facilityName;
  final String? districtName;

  /// Parses one event's `data` object off the REST `GET /merchant/orders`
  /// feed. Only [id] is required (its absence is a real error). Every other
  /// field falls back to a default: the feed is an event *log* that mixes full
  /// order events with identity-only `order.deleted` tombstones (no status /
  /// total / currency / items), and one such event must not throw and abort
  /// the whole order-list parse. Same leniency as [fromWireJson].
  factory OrderDataDto.fromJson(Map<String, dynamic> json) {
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
      fulfillmentType:
          FulfillmentType.fromWire(json['fulfillment_type']?.toString()),
      facilityName: json['facility_name'] as String?,
      districtName: json['district_name'] as String?,
    );
  }

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
      fulfillmentType:
          FulfillmentType.fromWire(json['fulfillment_type']?.toString()),
      facilityName: json['facility_name'] as String?,
      districtName: json['district_name'] as String?,
    );
  }
}
