import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/features/orders/data/models/order_data_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_event_dto.dart';
import 'package:mobile_merchant/features/orders/data/models/order_item_dto.dart';

Map<String, dynamic> wireEvent({String eventType = 'order.created'}) => {
      'event_id': 'evt_1',
      'event_type': eventType,
      'data': {
        'id': 'ord_1',
        'customer_id': 'guest_1',
        'customer_name': null,
        'customer_email': null,
        'status': 'pending',
        'total': 100,
        'currency': 'PHP',
        'created_at': '2026-08-21T06:35:14.918Z',
        'updated_at': '2026-08-21T06:35:14.918Z',
        'merchant_id': 'merch_1',
        'items': [
          {'product_id': 'p_1', 'product_name': 'Item', 'quantity': 1, 'price': 100},
        ],
      },
    };

void main() {
  group('OrderItemDto.fromWireJson', () {
    test('parses a well-formed item', () {
      final item = OrderItemDto.fromWireJson(
        {'product_id': 'p_1', 'product_name': 'Coffee', 'quantity': 2, 'price': 4.5},
      );
      expect(item.productId, 'p_1');
      expect(item.productName, 'Coffee');
      expect(item.quantity, 2);
      expect(item.price, 4.5);
    });

    test('falls back on missing / odd fields instead of throwing', () {
      final item = OrderItemDto.fromWireJson({'price': 3});
      expect(item.productId, '');
      expect(item.productName, '');
      expect(item.quantity, 1);
      expect(item.price, 3.0);
    });
  });

  group('OrderDataDto.fromWireJson', () {
    test('parses a full payload', () {
      final data = OrderDataDto.fromWireJson(wireEvent()['data'] as Map<String, dynamic>);
      expect(data.id, 'ord_1');
      expect(data.total, 100.0);
      expect(data.items, hasLength(1));
    });

    test('accepts total as a double', () {
      final json = wireEvent()['data'] as Map<String, dynamic>..['total'] = 12.75;
      expect(OrderDataDto.fromWireJson(json).total, 12.75);
    });

    test('missing optional fields fall back; a bad item still yields an item', () {
      final data = OrderDataDto.fromWireJson({
        'id': 'ord_2',
        'items': [
          {'garbage': true},
          'not-a-map',
        ],
      });
      expect(data.id, 'ord_2');
      expect(data.customerId, '');
      expect(data.status, 'unknown');
      expect(data.currency, '');
      expect(data.items, hasLength(1)); // the string entry is skipped
      expect(data.items.first.quantity, 1);
    });

    test('throws when id is absent (caller treats this as a dropped event)', () {
      expect(() => OrderDataDto.fromWireJson({'status': 'pending'}), throwsA(anything));
    });
  });

  group('OrderEventDto.fromWireJson', () {
    test('parses order.created / updated / cancelled', () {
      expect(OrderEventDto.fromWireJson(wireEvent())!.eventType, 'order.created');
      expect(OrderEventDto.fromWireJson(wireEvent(eventType: 'order.updated'))!.eventType, 'order.updated');
      expect(OrderEventDto.fromWireJson(wireEvent(eventType: 'order.cancelled'))!.eventType, 'order.cancelled');
    });

    test('synthesizes a positive id and a receivedAt', () {
      final event = OrderEventDto.fromWireJson(wireEvent())!;
      expect(event.id, greaterThan(0));
      expect(event.eventId, 'evt_1');
      expect(event.data.id, 'ord_1');
      expect(event.receivedAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('keeps any other order.* type verbatim', () {
      expect(OrderEventDto.fromWireJson(wireEvent(eventType: 'order.fulfilled'))!.eventType, 'order.fulfilled');
    });

    test('returns null for a non-order event type', () {
      expect(OrderEventDto.fromWireJson(wireEvent(eventType: 'payment.captured')), isNull);
      expect(OrderEventDto.fromWireJson(wireEvent(eventType: 'inventory.updated')), isNull);
    });

    test('returns null for missing / empty event_id', () {
      final noId = wireEvent()..remove('event_id');
      expect(OrderEventDto.fromWireJson(noId), isNull);
      expect(OrderEventDto.fromWireJson(wireEvent()..['event_id'] = ''), isNull);
    });

    test('returns null when data is malformed', () {
      expect(OrderEventDto.fromWireJson(wireEvent()..['data'] = {'no': 'id'}), isNull);
      expect(OrderEventDto.fromWireJson(wireEvent()..['data'] = 'nope'), isNull);
    });

    test('ignores REST-only wrapper fields when present', () {
      final withWrapper = wireEvent()
        ..['id'] = 40
        ..['received_at'] = '2026-08-21T06:35:15.549Z';
      final event = OrderEventDto.fromWireJson(withWrapper)!;
      expect(event.data.id, 'ord_1');
      expect(event.id, isNot(40)); // synthetic, not the REST wrapper id
    });
  });
}
