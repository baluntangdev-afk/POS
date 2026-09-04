import '../../../data/backend_api/errors/api_exception.dart';

/// Why a manual `PATCH /merchant/orders/{id}` attempt failed, in terms the
/// Orders screen can show the user. Kept separate from the app-wide
/// [AppError] hierarchy — this is a feature-local concern with its own
/// mapping.
enum OrderUpdateError {
  invalidUpdates,
  unknownOrder,
  unauthorized,
  rateLimited,
  network,
  unknown,
}

/// Maps a failed update attempt to a UI-facing reason. Anything that isn't an
/// [ApiException] (e.g. a local persistence failure) is
/// [OrderUpdateError.unknown]; a recognized backend `error` slug wins over the
/// HTTP status; a transport failure is [OrderUpdateError.network].
OrderUpdateError orderUpdateErrorFrom(Object error) {
  if (error is! ApiException) return OrderUpdateError.unknown;
  return switch (error) {
    NetworkException() => OrderUpdateError.network,
    ApiDecodingException() => OrderUpdateError.unknown,
    ApiUnknownException() => OrderUpdateError.unknown,
    ApiResponseException(:final code, :final statusCode) when code.isNotEmpty =>
      _fromCode(code) ?? _fromStatus(statusCode),
    ApiResponseException(:final statusCode) => _fromStatus(statusCode),
  };
}

OrderUpdateError? _fromCode(String code) => switch (code) {
  'invalid_updates' || 'invalid_request' => OrderUpdateError.invalidUpdates,
  'order_not_found' || 'unknown_order' => OrderUpdateError.unknownOrder,
  'unauthorized' ||
  'invalid_webhook_secret' ||
  'invalid_client' => OrderUpdateError.unauthorized,
  'rate_limited' || 'too_many_requests' => OrderUpdateError.rateLimited,
  _ => null,
};

OrderUpdateError _fromStatus(int? status) => switch (status) {
  400 || 422 => OrderUpdateError.invalidUpdates,
  401 || 403 => OrderUpdateError.unauthorized,
  404 => OrderUpdateError.unknownOrder,
  429 => OrderUpdateError.rateLimited,
  _ => OrderUpdateError.unknown,
};

extension OrderUpdateErrorMessage on OrderUpdateError {
  String get message => switch (this) {
    OrderUpdateError.invalidUpdates => 'That update isn\'t valid for this order.',
    OrderUpdateError.unknownOrder => 'This order is no longer available.',
    OrderUpdateError.unauthorized => 'Your session expired. Sign in again.',
    OrderUpdateError.rateLimited =>
      'Too many updates — wait a moment and try again.',
    OrderUpdateError.network =>
      'No connection. Check your network and try again.',
    OrderUpdateError.unknown => 'Couldn\'t update the order. Try again.',
  };
}
