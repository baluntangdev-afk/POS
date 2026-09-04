import '../../../data/backend_api/errors/api_exception.dart';

/// Why minting a live-orders WebSocket token via `POST /devices/token` failed,
/// in terms a settings / onboarding screen can show the user. Feature-local,
/// mirroring [WebhookAuthError].
enum DeviceTokenError {
  /// No `device_id` / `device_secret` is persisted yet — the device hasn't
  /// finished registering. Retrying can't fix it until registration lands.
  noDeviceCredentials,

  /// The device is registered but still awaiting merchant approval
  /// (`error: device_pending` / `not_approved`). Expected right after
  /// registration; clears once a reviewer approves the device.
  devicePendingApproval,

  /// The stored credentials were rejected — wrong secret, unknown device, or
  /// the device was revoked (`error: invalid_device` / `device_not_found` /
  /// `device_revoked`, or a bare 401/403). The device must re-register.
  invalidDeviceCredentials,

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

/// Maps an [ApiException] from `DeviceTokenApi.fetchToken` to a UI-facing
/// reason. A recognized backend `error` slug wins; otherwise the HTTP status
/// decides; a transport failure is [DeviceTokenError.network].
DeviceTokenError deviceTokenErrorFrom(ApiException error) => switch (error) {
  NetworkException() => DeviceTokenError.network,
  ApiDecodingException() => DeviceTokenError.unexpectedResponse,
  ApiUnknownException() => DeviceTokenError.unknown,
  ApiResponseException(:final code, :final statusCode) when code.isNotEmpty =>
    _fromCode(code) ?? _fromStatus(statusCode),
  ApiResponseException(:final statusCode) => _fromStatus(statusCode),
};

DeviceTokenError? _fromCode(String code) => switch (code) {
  'device_pending' ||
  'not_approved' ||
  'pending_approval' => DeviceTokenError.devicePendingApproval,
  'invalid_device' ||
  'device_not_found' ||
  'unknown_device' ||
  'device_revoked' ||
  'invalid_device_secret' => DeviceTokenError.invalidDeviceCredentials,
  'invalid_request' ||
  'invalid_merchant' ||
  'unknown_merchant' => DeviceTokenError.invalidRequest,
  'rate_limited' || 'too_many_requests' => DeviceTokenError.rateLimited,
  _ => null,
};

DeviceTokenError _fromStatus(int? status) => switch (status) {
  400 || 422 => DeviceTokenError.invalidRequest,
  401 || 403 => DeviceTokenError.invalidDeviceCredentials,
  429 => DeviceTokenError.rateLimited,
  final int s when s >= 500 => DeviceTokenError.serverError,
  _ => DeviceTokenError.unknown,
};

/// User-facing text for a failed token mint: the backend's own `message` from
/// the response when it sent one (for recoverable reasons), otherwise the
/// mapped copy for [reason]. Mirrors `webhookAuthMessageFrom`.
String deviceTokenMessageFrom(Object error, DeviceTokenError reason) {
  if (reason.isRecoverable &&
      error is ApiResponseException &&
      error.serverMessage.isNotEmpty) {
    return error.serverMessage;
  }
  return reason.message;
}

extension DeviceTokenErrorMessage on DeviceTokenError {
  String get message => switch (this) {
    DeviceTokenError.noDeviceCredentials =>
      'This device isn\'t registered yet. Live orders will connect once '
          'registration completes.',
    DeviceTokenError.devicePendingApproval =>
      'This device is still awaiting merchant approval. Live orders will '
          'connect once it\'s approved.',
    DeviceTokenError.invalidDeviceCredentials =>
      'This device\'s credentials were rejected. Re-register the device from '
          'Store Info.',
    DeviceTokenError.invalidRequest =>
      'The orders service rejected the connection request. Check the store ID.',
    DeviceTokenError.rateLimited =>
      'Too many attempts — waiting a moment before retrying.',
    DeviceTokenError.network =>
      'Can\'t reach the orders service. Check your network.',
    DeviceTokenError.unexpectedResponse =>
      'The orders service sent back something unexpected. Retrying.',
    DeviceTokenError.serverError =>
      'The orders service ran into a problem. Retrying shortly.',
    DeviceTokenError.unknown =>
      'Couldn\'t connect to the orders service. Retrying.',
  };

  /// Whether retrying the same request could ever succeed without the user (or
  /// a merchant reviewer) acting first.
  bool get isRecoverable => switch (this) {
    DeviceTokenError.noDeviceCredentials ||
    DeviceTokenError.invalidDeviceCredentials => false,
    _ => true,
  };
}

/// Raised by `DeviceTokenRepository` so callers get a typed [DeviceTokenError]
/// instead of a data-layer [ApiException].
class DeviceTokenException implements Exception {
  const DeviceTokenException(this.reason, this.message);

  final DeviceTokenError reason;

  /// User-facing text: the backend's own `message` when it sent one, otherwise
  /// the mapped copy for [reason]. See [deviceTokenMessageFrom].
  final String message;

  @override
  String toString() => 'DeviceTokenException(${reason.name})';
}
