import 'package:envied/envied.dart';

import 'app_env.dart';

part 'env.g.dart';

@Envied(path: '.env', useConstantCase: true)
final class Env implements AppEnv {
  Env();

  @EnviedField()
  @override
  final String backendApiBaseUrl = _Env.backendApiBaseUrl;

  @EnviedField(obfuscate: true)
  @override
  final String secureStorageKey = _Env.secureStorageKey;

  @EnviedField()
  @override
  final String ordersLiveFeedWsUrl = _Env.ordersLiveFeedWsUrl;

  @EnviedField()
  @override
  final String cartivoAuthApiBaseUrl = _Env.cartivoAuthApiBaseUrl;

  @EnviedField()
  @override
  final String ordersEventsApiBaseUrl = _Env.ordersEventsApiBaseUrl;

  @EnviedField()
  @override
  final String clientId = _Env.clientId;

  @EnviedField(obfuscate: true)
  @override
  final String webhookSecret = _Env.webhookSecret;

  @override
  bool get isDev => false;
}
