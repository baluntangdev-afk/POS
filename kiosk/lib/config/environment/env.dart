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

  @override
  bool get isDev => false;
}
