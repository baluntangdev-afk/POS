import 'package:envied/envied.dart';

import 'app_env.dart';

part 'env_dev.g.dart';

@Envied(path: '.env.dev', useConstantCase: true)
final class EnvDev implements AppEnv {
  EnvDev();

  @override
  @EnviedField()
  final String backendApiBaseUrl = _EnvDev.backendApiBaseUrl;

  @override
  @EnviedField(obfuscate: true)
  final String secureStorageKey = _EnvDev.secureStorageKey;

  @override
  @EnviedField()
  final String ordersLiveFeedWsUrl = _EnvDev.ordersLiveFeedWsUrl;

  @override
  bool get isDev => true;
}
