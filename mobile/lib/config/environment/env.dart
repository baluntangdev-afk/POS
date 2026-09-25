import 'package:envied/envied.dart';

import 'app_env.dart';

part 'env.g.dart';

@Envied(path: '.env', useConstantCase: true)
final class Env implements AppEnv {
  Env();

  @EnviedField()
  @override
  final String ordersEventsApiBaseUrl = _Env.ordersEventsApiBaseUrl;

  @EnviedField()
  @override
  final String clientId = _Env.clientId;

  @EnviedField(obfuscate: true)
  @override
  final String webhookSecret = _Env.webhookSecret;

  @EnviedField(defaultValue: '', obfuscate: true)
  @override
  final String csvExportPassword = _Env.csvExportPassword;

  @EnviedField(defaultValue: '')
  @override
  final String senderEmail = _Env.senderEmail;

  @EnviedField(defaultValue: '', obfuscate: true)
  @override
  final String senderAppPassword = _Env.senderAppPassword;

  /// Gates the orders-server settings dialog on the login screen (only shown
  /// when `SKIP_DEVICE_REGISTRATION` is off). Empty = the dialog can't be
  /// unlocked.
  @EnviedField(defaultValue: '', obfuscate: true)
  @override
  final String settingsPassword = _Env.settingsPassword;
}
