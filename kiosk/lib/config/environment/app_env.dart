import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class AppEnv {
  String get backendApiBaseUrl;
  String get replenishmentApiBaseUrl;
  String get cartivoAuthApiBaseUrl;
  String get secureStorageKey;
  bool get isDev;
}

/// Overridden in bootstrap with the concrete env (Env or EnvProd).
final appEnvProvider = Provider<AppEnv>((_) => throw UnimplementedError('appEnvProvider not overridden'));
