import '../../../../core/utils/app_logger.dart';
import 'order_event_dto.dart';

class MerchantOrdersDto {
  const MerchantOrdersDto({
    required this.merchantId,
    required this.events,
  });

  final String merchantId;

  /// Current-state event list: `order.deleted` tombstones are applied and
  /// removed here, and any event that fails to parse is dropped, so the list
  /// is safe to render and cache directly.
  final List<OrderEventDto> events;

  factory MerchantOrdersDto.fromJson(Map<String, dynamic> json) {
    final raw = json['events'];
    final rawList = raw is List ? raw : const [];

    // Pass 1 — collect every order id with an `order.deleted` tombstone,
    // reading the raw JSON directly. A tombstone whose `data` is empty / not a
    // map would fail to parse in pass 2 and be dropped, so its order id has to
    // be salvaged here or the order's older frames would resurrect it.
    final deletedOrderIds = <String>{};
    for (final entry in rawList) {
      if (entry is! Map) continue;
      if (entry['event_type'] != 'order.deleted') continue;
      final id = _rawOrderId(entry);
      if (id != null) deletedOrderIds.add(id);
    }

    // Pass 2 — parse the survivors. Skip tombstones (never listed) and any
    // event belonging to a deleted order. A parse failure is logged and
    // dropped rather than aborting the whole list.
    final events = <OrderEventDto>[];
    for (final entry in rawList) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['event_type'] == 'order.deleted') continue;
      try {
        final event = OrderEventDto.fromJson(entry);
        if (deletedOrderIds.contains(event.data.id)) continue;
        events.add(event);
      } catch (e, s) {
        AppLogger.logError('MerchantOrdersDto.fromJson', e, s);
      }
    }

    return MerchantOrdersDto(
      merchantId: json['merchant_id'] as String,
      events: events,
    );
  }

  /// Best-effort order-id extraction from a raw event map — covers the shapes
  /// an `order.deleted` tombstone might arrive in: `data: { id }`,
  /// `data: "<id>"`, or a top-level `order_id`.
  static String? _rawOrderId(Map<dynamic, dynamic> entry) {
    final data = entry['data'];
    if (data is Map) {
      final id = data['id'];
      if (id is String && id.isNotEmpty) return id;
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    final topLevel = entry['order_id'];
    if (topLevel is String && topLevel.isNotEmpty) return topLevel;
    return null;
  }
}
