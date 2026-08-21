import 'package:dart_mappable/dart_mappable.dart';

import '../../../data/backend_api/mappers/date_time_with_offset_mapper.dart';

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

@MappableClass(caseStyle: CaseStyle.snakeCase)
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
  final num price;

  static const fromJson = OrderEventItemMapper.fromJson;
}

/// `on_site` orders are required to carry [OrderData.facilityId]/[facilityName];
/// `pickup`/`delivery` never do. Null on `/api/test/*` orders, which don't
/// select a fulfillment type at all.
///
/// [other] is the fallback for values outside the documented set (e.g. the
/// webhook-receiver's own `/api/test/*` sandbox has been observed sending
/// `"TEST"`) so an unrecognized value doesn't crash event parsing.
@MappableEnum(caseStyle: CaseStyle.snakeCase, defaultValue: FulfillmentType.other)
enum FulfillmentType { onSite, pickup, delivery, other }

@MappableClass(caseStyle: CaseStyle.snakeCase, includeCustomMappers: [DateTimeWithOffsetMapper()])
class OrderData with OrderDataMappable {
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
  final FulfillmentType? fulfillmentType;
  final String? facilityId;
  final String? facilityName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderEventItem> items;
  final String merchantId;

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
