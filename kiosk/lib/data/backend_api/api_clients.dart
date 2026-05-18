import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import '../../network/http_client.dart';
import 'token_interceptor.dart';

final openApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (baseUrl: env.backendApiBaseUrl, interceptors: <Interceptor>[]);
  final client = httpClientProvider(options);
  return ref.watch(client);
});

final secureApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (
    baseUrl: env.backendApiBaseUrl,
    interceptors: [ref.watch(tokenInterceptorProvider)],
  );
  final client = httpClientProvider(options);
  return ref.watch(client);
});
