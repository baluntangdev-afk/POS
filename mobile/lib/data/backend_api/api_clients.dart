import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';

/// Client for the webhook-receiver's order-history REST endpoint
/// (`/webhooks/events`) — same host as the live orders WS feed
/// ([AppEnv.ordersLiveFeedWsUrl]), configured separately via
/// [AppEnv.ordersEventsApiBaseUrl] since it's a plain REST call rather than
/// a socket URL. Unauthenticated — this is the only REST client mobile has,
/// so no shared `httpClientProvider` abstraction is introduced; if a second
/// REST client shows up later, factor the shared bits out then.
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl));
});
