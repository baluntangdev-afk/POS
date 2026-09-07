import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_merchant/features/orders/data/repositories/orders_live_feed_repository.dart';

void main() {
  const validFrame = {
    'event_id': 'evt_1',
    'event_type': 'order.created',
    'data': {
      'id': 'ord_1',
      'customer_id': 'guest_1',
      'status': 'pending',
      'total': 100,
      'currency': 'PHP',
      'created_at': '2026-08-21T06:35:14.918Z',
      'updated_at': '2026-08-21T06:35:14.918Z',
      'merchant_id': 'merch_1',
      'items': <dynamic>[],
    },
  };

  group('parseOrderEventFrame', () {
    test('parses a valid JSON string frame', () {
      final event = parseOrderEventFrame(jsonEncode(validFrame));
      expect(event, isNotNull);
      expect(event!.eventId, 'evt_1');
      expect(event.data.id, 'ord_1');
    });

    test('returns null for a non-String frame', () {
      expect(parseOrderEventFrame(const <int>[1, 2, 3]), isNull);
      expect(parseOrderEventFrame(null), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(parseOrderEventFrame('{not json'), isNull);
    });

    test('returns null for a JSON array (not an object)', () {
      expect(parseOrderEventFrame('[1,2,3]'), isNull);
    });

    test('returns null for an unrecognized event type', () {
      final frame = jsonEncode({...validFrame, 'event_type': 'payment.captured'});
      expect(parseOrderEventFrame(frame), isNull);
    });
  });
}
