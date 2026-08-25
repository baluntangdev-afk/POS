import 'package:envied/envied.dart';

import 'app_env.dart';

part 'env.g.dart';

@Envied(path: '.env', useConstantCase: true)
final class Env implements AppEnv {
  Env();

  @EnviedField()
  @override
  final String ordersLiveFeedWsUrl = _Env.ordersLiveFeedWsUrl;

  @EnviedField()
  @override
  final String ordersEventsApiBaseUrl = _Env.ordersEventsApiBaseUrl;
}
