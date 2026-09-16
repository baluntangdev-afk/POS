import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import 'webhook_token_interceptor.dart';

// Dio's default `LogInterceptor.logPrint` wraps `print()` in an `assert()`,
// which is compiled out entirely in profile/release builds and is otherwise
// prone to being dropped by Android's logcat rate limiter under the volume
// this interceptor produces. `debugPrint` avoids both.
LogInterceptor _apiLogInterceptor() => LogInterceptor(
  requestBody: true,
  responseBody: true,
  logPrint: (o) => debugPrint(o.toString()),
);

final dpoSocketApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(ref.watch(webhookTokenInterceptorProvider))
    ..interceptors.add(_apiLogInterceptor());
});

final ordersAuthRefreshApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(_apiLogInterceptor());
});

/// Clean client for `POST /devices/token`: no `WebhookTokenInterceptor`, since
/// that endpoint authenticates from its request body and the interceptor's
/// 401 → `/auth/token` refresh-and-retry would be wrong here.
final deviceTokenApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(_apiLogInterceptor());
});
