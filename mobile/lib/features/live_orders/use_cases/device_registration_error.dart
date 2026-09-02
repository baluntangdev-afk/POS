import 'package:dio/dio.dart';

/// Why a `POST /devices/register` attempt failed, in terms a settings /
/// onboarding screen can show the user. Feature-local, with its own
/// HTTP-status mapping — mirrors [OrderUpdateError].
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

/// Maps a failed registration attempt to a UI-facing reason. A [DioException]
/// carrying a documented status code maps directly; a transport failure (no
/// response) is [DeviceRegistrationError.network]; a body-parse failure is
/// [DeviceRegistrationError.unexpectedResponse]; anything else is
/// [DeviceRegistrationError.unknown].
DeviceRegistrationError deviceRegistrationErrorFrom(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    switch (status) {
      case 400:
      case 422:
        return DeviceRegistrationError.invalidRequest;
      case 401:
      case 403:
        return DeviceRegistrationError.unauthorized;
      case 409:
        return DeviceRegistrationError.alreadyRegistered;
      case 429:
        return DeviceRegistrationError.rateLimited;
    }
    if (status != null && status >= 500) {
      return DeviceRegistrationError.serverError;
    }
    if (error.response == null) return DeviceRegistrationError.network;
    return DeviceRegistrationError.unknown;
  }
  if (error is FormatException) {
    return DeviceRegistrationError.unexpectedResponse;
  }
  return DeviceRegistrationError.unknown;
}

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
