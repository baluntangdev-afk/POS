import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

part 'order_event.mapper.dart';

/// The subset of the webhook-receiver's `event_type` values this kiosk
/// currently cares about. `payment.*` and `inventory.updated` are ignored —
/// see [OrderEventType.fromWire].
@MappableEnum()
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

@MappableClass()
class OrderEventItem with OrderEventItemMappable {
  const OrderEventItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String productName;
  final int quantity;
  final String price;

  static const fromJson = OrderEventItemMapper.fromJson;
}

@MappableClass()
class OrderData with OrderDataMappable {
  const OrderData({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.total,
    required this.currency,
    required this.items,
    required this.merchantIds,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String status;
  final String total;
  final String currency;
  final IList<OrderEventItem> items;
  final IList<String> merchantIds;

  static const fromJson = OrderDataMapper.fromJson;
}

@MappableClass()
class OrderEvent with OrderEventMappable {
  const OrderEvent({
    required this.eventId,
    required this.type,
    required this.data,
  });

  final String eventId;
  final OrderEventType type;
  final OrderData data;
}
