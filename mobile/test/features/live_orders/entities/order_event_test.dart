import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live_orders/entities/order_event.dart';

Map<String, dynamic> _wireEvent({String eventType = 'order.created'}) => {
  'event_id': 'evt_test-1',
  'event_type': eventType,
  'data': {
    'id': 'ord_1',
    'customer_id': 'guest_1',
    'customer_name': null,
    'customer_email': null,
    'status': 'pending',
    'total': 100,
    'currency': 'PHP',
    'district_id': 'dist_1',
    'district_name': 'District One',
    'fulfillment_type': 'on_site',
    'facility_id': 'fac_1',
    'facility_name': 'Table 1',
    'created_at': '2026-08-21T06:35:14.918Z',
    'updated_at': '2026-08-21T06:35:14.918Z',
    'items': [
      {'product_id': 'item_1', 'product_name': 'Item', 'quantity': 1, 'price': 100},
    ],
    'merchant_id': 'merch_1',
  },
};

void main() {
  group('OrderEvent.fromWireJson', () {
    test('parses a valid order.created event', () {
      final event = OrderEvent.fromWireJson(_wireEvent());

      expect(event, isNotNull);
      expect(event!.eventId, 'evt_test-1');
      expect(event.type, OrderEventType.created);
      expect(event.data.id, 'ord_1');
      expect(event.data.total, 100);
      expect(event.data.fulfillmentType, FulfillmentType.onSite);
    });

    test('parses order.updated and order.cancelled', () {
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'order.updated'))!.type, OrderEventType.updated);
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'order.cancelled'))!.type, OrderEventType.cancelled);
    });

    test('returns null for an unrecognized event_type', () {
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'payment.captured')), isNull);
    });

    test('returns null when data is malformed instead of throwing', () {
      final broken = _wireEvent();
      broken['data'] = {'not': 'a valid order payload'};

      expect(OrderEvent.fromWireJson(broken), isNull);
    });

    test('ignores extra fields present only on the REST payload (id/received_at/created_at wrapper)', () {
      final withExtra = {..._wireEvent(), 'id': 40, 'received_at': '2026-08-21T06:35:15.549Z'};

      final event = OrderEvent.fromWireJson(withExtra);

      expect(event, isNotNull);
      expect(event!.data.id, 'ord_1');
    });
  });
}
