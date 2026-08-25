import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class AppEnv {
  String get ordersLiveFeedWsUrl;
  String get ordersEventsApiBaseUrl;
}

/// Overridden in main() with the concrete env (Env, backed by .env via
/// envied) — mirrors the kiosk app's `appEnvProvider`.
final appEnvProvider = Provider<AppEnv>((_) => throw UnimplementedError('appEnvProvider not overridden'));
