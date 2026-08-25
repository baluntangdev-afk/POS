/// The subset of the webhook-receiver's `event_type` values this app
/// currently cares about. `payment.*` and `inventory.updated` are ignored —
/// see [OrderEventType.fromWire].
enum OrderEventType {
  created,
  updated,
  cancelled;

  static OrderEventType? fromWire(String eventType) {
    switch (eventType) {
      case 'order.created':
        return OrderEventType.created;
      case 'order.updated':
        return OrderEventType.updated;
      case 'order.cancelled':
        return OrderEventType.cancelled;
      default:
        return null;
    }
  }
}

class OrderEventItem {
  const OrderEventItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String productName;
  final int quantity;
  final num price;

  factory OrderEventItem.fromJson(Map<String, dynamic> json) => OrderEventItem(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        price: json['price'] as num,
      );
}

enum FulfillmentType {
  onSite,
  pickup,
  delivery,
  other;

  static FulfillmentType fromWire(String? value) {
    switch (value) {
      case 'on_site':
        return FulfillmentType.onSite;
      case 'pickup':
        return FulfillmentType.pickup;
      case 'delivery':
        return FulfillmentType.delivery;
      default:
        // Unrecognized values (e.g. the webhook-receiver's own sandbox has
        // been observed sending "TEST") fall back here instead of throwing,
        // so an unfamiliar value doesn't crash event parsing.
        return FulfillmentType.other;
    }
  }

  /// Inverse of [fromWire] — used only when re-serializing for local
  /// storage (see [OrderData.toJson]), so a persisted-then-reloaded order
  /// round-trips through the same values instead of drifting to [other].
  String get wireValue => switch (this) {
        FulfillmentType.onSite => 'on_site',
        FulfillmentType.pickup => 'pickup',
        FulfillmentType.delivery => 'delivery',
        FulfillmentType.other => 'other',
      };
}

/// `on_site` orders are required to carry [OrderData.facilityId]/
/// [facilityName]; `pickup`/`delivery` never do.
class OrderData {
  const OrderData({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.total,
    required this.currency,
    required this.districtId,
    required this.districtName,
    required this.fulfillmentType,
    required this.facilityId,
    required this.facilityName,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.merchantId,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String? customerEmail;
  final String status;
  final num total;
  final String currency;
  final String? districtId;
  final String? districtName;
  final FulfillmentType fulfillmentType;
  final String? facilityId;
  final String? facilityName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderEventItem> items;
  final String merchantId;

  factory OrderData.fromJson(Map<String, dynamic> json) => OrderData(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: json['customer_name'] as String?,
        customerEmail: json['customer_email'] as String?,
        status: json['status'] as String,
        total: json['total'] as num,
        currency: json['currency'] as String,
        districtId: json['district_id'] as String?,
        districtName: json['district_name'] as String?,
        fulfillmentType: FulfillmentType.fromWire(json['fulfillment_type'] as String?),
        facilityId: json['facility_id'] as String?,
        facilityName: json['facility_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderEventItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        merchantId: json['merchant_id'] as String,
      );

  /// Round-trips through [OrderEventsLocalRepository] storage — only the
  /// fields the Orders screen actually renders need to survive the trip.
  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'status': status,
        'total': total,
        'currency': currency,
        'district_id': districtId,
        'district_name': districtName,
        'fulfillment_type': fulfillmentType.wireValue,
        'facility_id': facilityId,
        'facility_name': facilityName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'items': items
            .map((i) => {
                  'product_id': i.productId,
                  'product_name': i.productName,
                  'quantity': i.quantity,
                  'price': i.price,
                })
            .toList(),
        'merchant_id': merchantId,
      };
}

class OrderEvent {
  const OrderEvent({
    required this.eventId,
    required this.type,
    required this.data,
  });

  final String eventId;
  final OrderEventType type;
  final OrderData data;

  /// Parses one event off either the live WS feed or the REST history
  /// endpoint — both send `{event_type, event_id, data, ...}`, the REST
  /// payload just wraps extra fields (`id`, `received_at`, `created_at`)
  /// around the same three. Returns `null` (never throws) for an
  /// unrecognized `event_type` or a malformed/missing `data`, so a single
  /// bad row never takes down a whole batch of events.
  static OrderEvent? fromWireJson(Map<String, dynamic> json) {
    try {
      final type = OrderEventType.fromWire(json['event_type'] as String);
      if (type == null) return null;
      return OrderEvent(
        eventId: json['event_id'] as String,
        type: type,
        data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }
}
