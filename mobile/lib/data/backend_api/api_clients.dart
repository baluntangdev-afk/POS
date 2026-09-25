import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/orders_server_url.dart';
import '../../core/services/clock/app_clock.dart';
import 'webhook_token_interceptor.dart';

// Dio's default `LogInterceptor.logPrint` wraps `print()` in an `assert()`,
// which is compiled out entirely in profile/release builds and is otherwise
// prone to being dropped by Android's logcat rate limiter under the volume
// this interceptor produces. `debugPrint` avoids both.
//
// A request/response body prints as a single line, and Android's logcat
// truncates any line past ~4KB — so long bodies still get cut off even with
// `debugPrint`. Splitting on existing newlines and re-chunking anything still
// oversized keeps the full body readable.
const _kLogChunkSize = 800;

void _debugPrintChunked(String text) {
  for (final line in text.split('\n')) {
    if (line.length <= _kLogChunkSize) {
      debugPrint(line);
      continue;
    }
    for (var i = 0; i < line.length; i += _kLogChunkSize) {
      final end = i + _kLogChunkSize < line.length ? i + _kLogChunkSize : line.length;
      debugPrint(line.substring(i, end));
    }
  }
}

LogInterceptor _apiLogInterceptor() => LogInterceptor(
  requestHeader: true,
  requestBody: true,
  responseHeader: true,
  responseBody: true,
  logPrint: (o) => _debugPrintChunked(o.toString()),
);

/// Every backend response carries a standard HTTP `date` header — reading it
/// lets [AppClock] correct for a wrong device clock without needing a
/// dedicated "server time" endpoint, and it works over LAN alone since it
/// doesn't require real internet access.
InterceptorsWrapper _serverTimeInterceptor(AppClock appClock) => InterceptorsWrapper(
  onResponse: (response, handler) {
    final dateHeader = response.headers.value('date');
    if (dateHeader != null) {
      try {
        unawaited(appClock.recordServerTime(HttpDate.parse(dateHeader)));
      } catch (_) {
        // Malformed/missing header — leave the cached offset as-is.
      }
    }
    handler.next(response);
  },
);

final dpoSocketApiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(ordersServerUrlProvider);
  final appClock = ref.watch(appClockProvider);
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(ref.watch(webhookTokenInterceptorProvider))
    ..interceptors.add(_serverTimeInterceptor(appClock))
    ..interceptors.add(_apiLogInterceptor());
});

final ordersAuthRefreshApiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(ordersServerUrlProvider);
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(_apiLogInterceptor());
});

/// Clean client for `POST /devices/token`: no `WebhookTokenInterceptor`, since
/// that endpoint authenticates from its request body and the interceptor's
/// 401 → `/auth/token` refresh-and-retry would be wrong here.
final deviceTokenApiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(ordersServerUrlProvider);
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(_apiLogInterceptor());
});
