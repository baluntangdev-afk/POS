import '../../../data/backend_api/errors/api_exception.dart';

/// Why a `POST /auth/token` attempt against the orders-events backend failed,
/// in terms a settings / onboarding screen can show the user. Feature-local,
/// mirroring [OrderUpdateError] and [DeviceRegistrationError].
enum WebhookAuthError {
  /// `WEBHOOK_SECRET` baked into this build doesn't match what the backend
  /// expects (`error: invalid_webhook_secret`). Retrying can't fix it.
  invalidWebhookSecret,

  /// `CLIENT_ID` is unknown or not permitted
  /// (`error: invalid_client` / `unknown_client`). Also unrecoverable.
  invalidClient,

  /// Credentials were rejected but the backend didn't say which field was
  /// wrong (a bare 401/403).
  unauthorized,

  /// The request was malformed or named an unknown merchant.
  invalidRequest,

  /// Too many token requests — back off and retry.
  rateLimited,

  /// The backend is unreachable or returned no response.
  network,

  /// The backend answered but the payload couldn't be parsed.
  unexpectedResponse,

  /// The backend returned 5xx.
  serverError,

  /// Anything else.
  unknown,
}

/// Maps an [ApiException] from `AuthApi.fetchToken` to a UI-facing reason. A
/// recognized backend `error` slug wins; otherwise the HTTP status decides;
/// a transport failure is [WebhookAuthError.network].
WebhookAuthError webhookAuthErrorFrom(ApiException error) => switch (error) {
  NetworkException() => WebhookAuthError.network,
  ApiDecodingException() => WebhookAuthError.unexpectedResponse,
  ApiUnknownException() => WebhookAuthError.unknown,
  ApiResponseException(:final code, :final statusCode) when code.isNotEmpty =>
    _fromCode(code) ?? _fromStatus(statusCode),
  ApiResponseException(:final statusCode) => _fromStatus(statusCode),
};

WebhookAuthError? _fromCode(String code) => switch (code) {
  'invalid_webhook_secret' => WebhookAuthError.invalidWebhookSecret,
  'invalid_client' ||
  'unknown_client' ||
  'unauthorized_client' => WebhookAuthError.invalidClient,
  'invalid_request' ||
  'invalid_merchant' ||
  'unknown_merchant' => WebhookAuthError.invalidRequest,
  'rate_limited' || 'too_many_requests' => WebhookAuthError.rateLimited,
  _ => null,
};

/// User-facing text for a failed token mint: the backend's own `message` from
/// the response when it sent one, otherwise the mapped copy for the error
/// [reason]. Mirrors `deviceRegistrationMessageFrom`.
///
/// The unrecoverable build-config reasons ([WebhookAuthError.invalidWebhookSecret],
/// [WebhookAuthError.invalidClient]) keep their curated copy, which tells the
/// user to reinstall — more actionable than the backend's bare "secret is not
/// correct". Every other reason shows the backend's verbatim message.
String webhookAuthMessageFrom(Object error, WebhookAuthError reason) {
  if (reason.isRecoverable &&
      error is ApiResponseException &&
      error.serverMessage.isNotEmpty) {
    return error.serverMessage;
  }
  return reason.message;
}

WebhookAuthError _fromStatus(int? status) => switch (status) {
  400 || 422 => WebhookAuthError.invalidRequest,
  401 || 403 => WebhookAuthError.unauthorized,
  429 => WebhookAuthError.rateLimited,
  final int s when s >= 500 => WebhookAuthError.serverError,
  _ => WebhookAuthError.unknown,
};

extension WebhookAuthErrorMessage on WebhookAuthError {
  String get message => switch (this) {
    WebhookAuthError.invalidWebhookSecret =>
      'This app build has the wrong webhook secret. Reinstall with the '
          'correct configuration.',
    WebhookAuthError.invalidClient =>
      'This app build isn\'t recognized by the orders service.',
    WebhookAuthError.unauthorized =>
      'The orders service rejected this app\'s credentials.',
    WebhookAuthError.invalidRequest =>
      'The orders service rejected the sign-in request. Check the store ID.',
    WebhookAuthError.rateLimited =>
      'Too many attempts — wait a moment and try again.',
    WebhookAuthError.network =>
      'Can\'t reach the orders service. Check your network and try again.',
    WebhookAuthError.unexpectedResponse =>
      'The orders service sent back something unexpected. Try again.',
    WebhookAuthError.serverError =>
      'The orders service ran into a problem. Try again shortly.',
    WebhookAuthError.unknown =>
      'Couldn\'t connect to the orders service. Try again.',
  };

  /// Whether retrying the same request could ever succeed. A wrong secret or
  /// unknown client is a build-config problem — a reconnect loop won't clear
  /// it.
  bool get isRecoverable => switch (this) {
    WebhookAuthError.invalidWebhookSecret ||
    WebhookAuthError.invalidClient => false,
    _ => true,
  };
}

/// Raised by `WebhookAuthRepository` so callers get a typed [WebhookAuthError]
/// instead of a data-layer [ApiException].
class WebhookAuthException implements Exception {
  const WebhookAuthException(this.reason, this.message);

  final WebhookAuthError reason;

  /// User-facing text: the backend's own `message` when it sent one, otherwise
  /// the mapped copy for [reason]. See [webhookAuthMessageFrom].
  final String message;

  @override
  String toString() => 'WebhookAuthException(${reason.name})';
}
