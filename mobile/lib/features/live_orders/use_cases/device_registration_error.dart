import '../../../data/backend_api/errors/api_exception.dart';

/// Why a `POST /devices/register` attempt failed, in terms a settings /
/// onboarding screen can show the user. Feature-local, mirroring
/// [OrderUpdateError].
enum DeviceRegistrationError {
  /// The request body was rejected (missing/invalid fields).
  invalidRequest,

  /// Caller isn't allowed to register a device (bad/absent credentials).
  unauthorized,

  /// A device with this `install_id` is already registered for the merchant.
  alreadyRegistered,

  /// Too many registration attempts — back off and retry.
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

/// Maps a failed registration attempt to a UI-facing reason. Anything that
/// isn't an [ApiException] is [DeviceRegistrationError.unknown]; a recognized
/// backend `error` slug wins over the HTTP status; a transport failure is
/// [DeviceRegistrationError.network]; a body-parse failure is
/// [DeviceRegistrationError.unexpectedResponse].
DeviceRegistrationError deviceRegistrationErrorFrom(Object error) {
  if (error is! ApiException) return DeviceRegistrationError.unknown;
  return switch (error) {
    NetworkException() => DeviceRegistrationError.network,
    ApiDecodingException() => DeviceRegistrationError.unexpectedResponse,
    ApiUnknownException() => DeviceRegistrationError.unknown,
    ApiResponseException(:final code, :final statusCode) when code.isNotEmpty =>
      _fromCode(code) ?? _fromStatus(statusCode),
    ApiResponseException(:final statusCode) => _fromStatus(statusCode),
  };
}

/// User-facing text for a failed registration: the backend's own `message`
/// from the response when it sent one, otherwise the mapped copy for the
/// error [reason]. Used for the failure dialog.
String deviceRegistrationMessageFrom(
  Object error,
  DeviceRegistrationError reason,
) {
  if (error is ApiResponseException && error.serverMessage.isNotEmpty) {
    return error.serverMessage;
  }
  return reason.message;
}

DeviceRegistrationError? _fromCode(String code) => switch (code) {
  'invalid_request' ||
  'invalid_device' => DeviceRegistrationError.invalidRequest,
  'unauthorized' ||
  'invalid_webhook_secret' ||
  'invalid_client' => DeviceRegistrationError.unauthorized,
  'already_registered' ||
  'device_exists' => DeviceRegistrationError.alreadyRegistered,
  'rate_limited' ||
  'too_many_requests' => DeviceRegistrationError.rateLimited,
  _ => null,
};

DeviceRegistrationError _fromStatus(int? status) => switch (status) {
  400 || 422 => DeviceRegistrationError.invalidRequest,
  401 || 403 => DeviceRegistrationError.unauthorized,
  409 => DeviceRegistrationError.alreadyRegistered,
  429 => DeviceRegistrationError.rateLimited,
  final int s when s >= 500 => DeviceRegistrationError.serverError,
  _ => DeviceRegistrationError.unknown,
};

extension DeviceRegistrationErrorMessage on DeviceRegistrationError {
  String get message => switch (this) {
    DeviceRegistrationError.invalidRequest =>
      'Some device details are missing or invalid.',
    DeviceRegistrationError.unauthorized =>
      'This app isn\'t authorized to register a device.',
    DeviceRegistrationError.alreadyRegistered =>
      'This device is already registered.',
    DeviceRegistrationError.rateLimited =>
      'Too many attempts — wait a moment and try again.',
    DeviceRegistrationError.network =>
      'No connection. Check your network and try again.',
    DeviceRegistrationError.unexpectedResponse =>
      'The server sent back something unexpected. Try again.',
    DeviceRegistrationError.serverError =>
      'The server ran into a problem. Try again shortly.',
    DeviceRegistrationError.unknown =>
      'Couldn\'t register this device. Try again.',
  };
}
