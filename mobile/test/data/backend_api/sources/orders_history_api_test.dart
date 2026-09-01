import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/environment/app_env.dart';
import 'package:mobile/data/backend_api/sources/orders_history_api.dart';

class _FakeAppEnv implements AppEnv {
  @override
  final String clientId = 'client_123';

  @override
  final String webhookSecret = 'shh';

  @override
  final String ordersLiveFeedWsUrl = '';

  @override
  final String ordersEventsApiBaseUrl = '';

  @override
  final String csvExportPassword = '';

  @override
  final String senderEmail = '';

  @override
  final String senderAppPassword = '';
}

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
      final api = OrdersHistoryApi(dio, _FakeAppEnv());

      final events = await api.fetchEvents('merch_1');

      expect(events, hasLength(1));
      expect(events.single.data.id, 'ord_1');
      expect(adapter.lastRequest!.path, '/merchant/orders');
      expect(adapter.lastRequest!.queryParameters['merchant_id'], 'merch_1');
    });
  });

  group('OrdersHistoryApi.fetchToken', () {
    test('posts webhook credentials and decodes the returned token', () async {
      final adapter = _FakeHttpClientAdapter(
        jsonEncode({'merchant_id': 'merch_1', 'token': 'eyJ...', 'exp': 1787544197}),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))..httpClientAdapter = adapter;
      final api = OrdersHistoryApi(dio, _FakeAppEnv());

      final dto = await api.fetchToken('merch_1');

      expect(dto.merchantId, 'merch_1');
      expect(dto.token, 'eyJ...');
      expect(dto.exp, 1787544197);
      expect(adapter.lastRequest!.path, '/auth/token');
      expect(adapter.lastRequest!.data, {
        'webhook_secret': 'shh',
        'client_id': 'client_123',
        'merchant_id': 'merch_1',
      });
    });

    test('throws instead of swallowing a failed request', () async {
      final failingAdapter = _FakeHttpClientAdapter('Internal Server Error', statusCode: 500);
      final failingDio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))
        ..httpClientAdapter = failingAdapter;
      final api = OrdersHistoryApi(failingDio, _FakeAppEnv());

      expect(() => api.fetchToken('merch_1'), throwsA(isA<DioException>()));
    });
  });
}
