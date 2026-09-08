import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessors over the values loaded from `.env` by [dotenv].
///
/// Nothing else in the app should read [dotenv] directly. All getters fall back
/// to a safe default when `.env` has not been loaded (e.g. in widget tests).
class EnvConfig {
  const EnvConfig._();

  static String? _get(String key) =>
      dotenv.isInitialized ? dotenv.maybeGet(key) : null;

  static String get apiBaseUrl =>
      _get('API_BASE_URL') ?? 'http://10.0.2.2:3000/api/v1';

  static String get appName => _get('APP_NAME') ?? 'DPO Merchant';

  static bool get enableLogging =>
      (_get('ENABLE_LOGGING') ?? 'false').toLowerCase() == 'true';

  static String get settingsPassword => _get('SETTINGS_PASSWORD') ?? '';

  static String get webhookSecret => _get('WEBHOOK_SECRET') ?? '';

  static String get clientId => _get('CLIENT_ID') ?? '';

  /// Derives the WebSocket base URL from [apiBaseUrl] by stripping the path
  /// and converting the scheme (http → ws, https → wss).
  static String get wsBaseUrl {
    final apiUri = Uri.parse(apiBaseUrl);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    // Uri only strips a default port for http/https, not ws/wss — so drop the
    // port ourselves when it matches the scheme default to avoid a redundant
    // `:443` / `:80` in the serialized URL.
    final isDefaultPort = (scheme == 'wss' && apiUri.port == 443) ||
        (scheme == 'ws' && apiUri.port == 80);
    return Uri(
      scheme: scheme,
      host: apiUri.host,
      port: isDefaultPort ? null : apiUri.port,
    ).toString();
  }
}
