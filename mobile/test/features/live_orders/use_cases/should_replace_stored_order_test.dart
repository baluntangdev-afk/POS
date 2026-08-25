import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live_orders/entities/order_event.dart';
import 'package:mobile/features/live_orders/use_cases/should_replace_stored_order.dart';

OrderData _orderData({required DateTime updatedAt}) {
  return OrderData(
    id: 'ord_1',
    customerId: 'guest_1',
    customerName: null,
    customerEmail: null,
    status: 'pending',
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
  );
}

void main() {
  group('shouldReplaceStoredOrder', () {
    test('replaces when there is no existing row', () {
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: null, incoming: incoming), isTrue);
    });

    test('replaces when the incoming order is newer', () {
      final existing = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 12));

      expect(shouldReplaceStoredOrder(existing: existing, incoming: incoming), isTrue);
    });

    test('replaces when the incoming order has the same updatedAt', () {
      final same = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: same, incoming: same), isTrue);
    });

    test('does not replace when the incoming order is older', () {
      final existing = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 12));
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: existing, incoming: incoming), isFalse);
    });
  });
}
