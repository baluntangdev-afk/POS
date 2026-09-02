import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import 'webhook_token_interceptor.dart';

final dpoSocketApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(ref.watch(webhookTokenInterceptorProvider))
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
});

final ordersAuthRefreshApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
});
