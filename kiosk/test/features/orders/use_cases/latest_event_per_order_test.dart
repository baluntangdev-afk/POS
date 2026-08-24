import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/orders/entities/order_event.dart';
import 'package:pos_app/features/orders/use_cases/latest_event_per_order.dart';

OrderEvent _event({required String orderId, required DateTime updatedAt, required OrderEventType type}) {
  return OrderEvent(
    eventId: 'evt_$orderId-${updatedAt.microsecondsSinceEpoch}',
    type: type,
    data: OrderData(
      id: orderId,
      customerId: 'guest_1',
      customerName: null,
      customerEmail: null,
      status: type == OrderEventType.cancelled ? 'cancelled' : 'pending',
      total: 100,
      currency: 'PHP',
      districtId: 'dist_1',
      districtName: 'District One',
      fulfillmentType: FulfillmentType.onSite,
      facilityId: 'fac_1',
      facilityName: 'Table 1',
      createdAt: updatedAt,
      updatedAt: updatedAt,
      items: const [],
      merchantId: 'merch_1',
    ),
  );
}

void main() {
  test('keeps only the latest event per order, across multiple orders', () {
    final created = _event(
      orderId: 'ord_1',
      updatedAt: DateTime.utc(2026, 1, 1, 10),
      type: OrderEventType.created,
    );
    final updated = _event(
      orderId: 'ord_1',
      updatedAt: DateTime.utc(2026, 1, 1, 11),
      type: OrderEventType.updated,
    );
    final otherOrder = _event(
      orderId: 'ord_2',
      updatedAt: DateTime.utc(2026, 1, 1, 9),
      type: OrderEventType.created,
    );

    final result = latestEventPerOrder([created, updated, otherOrder]);

    expect(result, hasLength(2));
    expect(result.firstWhere((e) => e.data.id == 'ord_1').type, OrderEventType.updated);
    expect(result.firstWhere((e) => e.data.id == 'ord_2').type, OrderEventType.created);
  });

  test('returns an empty list for an empty input', () {
    expect(latestEventPerOrder(const []), isEmpty);
  });
}
