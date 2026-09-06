/// Non-secret, compile-time constants for the app.
///
/// Values that vary per environment or hold secrets belong in `.env` and are
/// read through [EnvConfig] instead.
class AppConfig {
  const AppConfig._();

  /// Short network timeout — governs how fast an unreachable server surfaces
  /// an error.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Longer timeout — allows for legitimately slow large payloads.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// How many times [RetryInterceptor] retries a pure connection error.
  static const int maxNetworkRetries = 2;

  /// Secure-storage key holding a user-supplied API base URL override.
  static const String customApiBaseUrlKey = 'custom_api_base_url';

  /// Secure-storage key holding the bearer token.
  static const String authTokenKey = 'auth_token';
}
