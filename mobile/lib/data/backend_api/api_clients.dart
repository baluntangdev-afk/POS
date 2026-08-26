import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import 'webhook_token_interceptor.dart';

/// Client for the webhook-receiver's order-history REST endpoint
/// (`/merchant/orders`) — same host as the live orders WS feed
/// ([AppEnv.ordersLiveFeedWsUrl]), configured separately via
/// [AppEnv.ordersEventsApiBaseUrl] since it's a plain REST call rather than
/// a socket URL. Authorized via [WebhookTokenInterceptor], which attaches
/// the bearer token issued by that same host's `/auth/token`. This is the
/// only REST client mobile has, so no shared `httpClientProvider`
/// abstraction is introduced; if a second REST client shows up later,
/// factor the shared bits out then.
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(ref.watch(webhookTokenInterceptorProvider))
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
});

/// Unauthenticated client to the same webhook-receiver host, used only by
/// [WebhookTokenInterceptor] to call `/auth/token` itself — kept separate
/// from [ordersEventsApiClientProvider] so that call can never recurse back
/// into the interceptor that's issuing it.
final ordersAuthRefreshApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl))
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
});
