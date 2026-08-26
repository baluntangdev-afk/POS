import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import '../../network/http_client.dart';
import 'token_interceptor.dart';
import 'webhook_token_interceptor.dart';

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

/// Client for the webhook-receiver's REST endpoints (order status/cancel) —
/// a separate, unauthenticated service from the main backend, on its own
/// host/port ([AppEnv.cartivoAuthApiBaseUrl]).
final cartivoApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (baseUrl: env.cartivoAuthApiBaseUrl, interceptors: <Interceptor>[]);
  final client = httpClientProvider(options);
  return ref.watch(client);
});

/// Client for the webhook-receiver's order-history REST endpoint
/// (`/webhooks/events`) — same host as the live orders WS feed
/// ([AppEnv.ordersLiveFeedWsUrl]), configured separately via
/// [AppEnv.ordersEventsApiBaseUrl] since it's a plain REST call rather than
/// a socket URL. Authorized via [WebhookTokenInterceptor], which attaches
/// the bearer token issued by that same host's `/auth/token`.
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (
    baseUrl: env.ordersEventsApiBaseUrl,
    interceptors: [ref.watch(webhookTokenInterceptorProvider)],
  );
  final client = httpClientProvider(options);
  return ref.watch(client);
});

/// Unauthenticated client to the same webhook-receiver host, used only by
/// [WebhookTokenInterceptor] to call `/auth/token` itself — kept separate
/// from [ordersEventsApiClientProvider] so that call can never recurse back
/// into the interceptor that's issuing it.
final ordersAuthRefreshApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (baseUrl: env.ordersEventsApiBaseUrl, interceptors: <Interceptor>[]);
  final client = httpClientProvider(options);
  return ref.watch(client);
});
