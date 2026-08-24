import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/backend_api/sources/orders_history_api.dart';
import 'package:pos_app/features/orders/entities/order_event.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _wireEvent(String orderId, String eventType, String updatedAt) => {
  'event_id': 'evt_$orderId-$eventType',
  'event_type': eventType,
  'data': {
    'id': orderId,
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
    'created_at': updatedAt,
    'updated_at': updatedAt,
    'items': const <dynamic>[],
    'merchant_id': 'merch_1',
  },
};

void main() {
  group('OrdersHistoryApi.fetchEvents', () {
    late _FakeHttpClientAdapter adapter;
    late Dio dio;

    setUp(() {
      adapter = _FakeHttpClientAdapter(
        jsonEncode({
          'merchant_id': 'merch_1',
          'events': [
            _wireEvent('ord_1', 'order.created', '2026-08-21T06:35:14.918Z'),
            _wireEvent('ord_2', 'payment.captured', '2026-08-21T06:36:00.000Z'), // dropped
          ],
        }),
      );
      dio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))..httpClientAdapter = adapter;
    });

    test('fetches, decodes, and drops unrecognized event types', () async {
      final api = OrdersHistoryApi(dio);

      final events = await api.fetchEvents('merch_1');

      expect(events, hasLength(1));
      expect(events.single.data.id, 'ord_1');
      expect(adapter.lastRequest!.path, '/webhooks/events');
      expect(adapter.lastRequest!.queryParameters['merchant_id'], 'merch_1');
    });
  });
}
