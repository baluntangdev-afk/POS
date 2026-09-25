import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/environment/app_env.dart';
import 'package:mobile/data/backend_api/errors/api_exception.dart';
import 'package:mobile/data/backend_api/sources/auth_api.dart';

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

void main() {
  group('AuthApi.fetchToken', () {
    test('posts webhook credentials and decodes the returned token', () async {
      final adapter = _FakeHttpClientAdapter(
        jsonEncode({'merchant_id': 'merch_1', 'token': 'eyJ...', 'exp': 1787544197}),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))..httpClientAdapter = adapter;
      final api = AuthApi(dio, _FakeAppEnv());

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

    test('throws an ApiException instead of swallowing a failed request', () async {
      final failingAdapter = _FakeHttpClientAdapter('Internal Server Error', statusCode: 500);
      final failingDio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))
        ..httpClientAdapter = failingAdapter;
      final api = AuthApi(failingDio, _FakeAppEnv());

      expect(() => api.fetchToken('merch_1'), throwsA(isA<ApiException>()));
    });
  });
}
