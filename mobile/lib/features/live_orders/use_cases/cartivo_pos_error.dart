import '../../../data/backend_api/errors/api_exception.dart';

/// Why a Cartivo `/pos/*` call failed, in terms the UI can show. Feature-local,
/// like [OrderUpdateError].
enum CartivoPosError {
  unauthorized,
  merchantMismatch,
  unknownOrder,
  orderNotFound,
  reasonRequired,
  invalidTransition,
  serviceUnavailable,
  network,
  unknown,
}

CartivoPosError cartivoPosErrorFrom(Object error) {
  if (error is! ApiException) return CartivoPosError.unknown;
  return switch (error) {
    NetworkException() => CartivoPosError.network,
    ApiDecodingException() => CartivoPosError.unknown,
    ApiUnknownException() => CartivoPosError.unknown,
    ApiResponseException(:final code, :final statusCode) when code.isNotEmpty =>
      _fromCode(code) ?? _fromStatus(statusCode),
    ApiResponseException(:final statusCode) => _fromStatus(statusCode),
  };
}

CartivoPosError? _fromCode(String code) => switch (code) {
  'missing_bearer_token' || 'invalid_or_expired_token' => CartivoPosError.unauthorized,
  'merchant_id_mismatch' => CartivoPosError.merchantMismatch,
  'unknown_order' => CartivoPosError.unknownOrder,
  'order_not_found' => CartivoPosError.orderNotFound,
  'reason_required' => CartivoPosError.reasonRequired,
  'invalid_transition' => CartivoPosError.invalidTransition,
  'wms_unavailable' => CartivoPosError.serviceUnavailable,
  _ => null,
};

CartivoPosError _fromStatus(int? status) => switch (status) {
  401 => CartivoPosError.unauthorized,
  403 => CartivoPosError.merchantMismatch,
  404 => CartivoPosError.orderNotFound,
  502 => CartivoPosError.serviceUnavailable,
  _ => CartivoPosError.unknown,
};

/// A classified failure plus the text to show for it. Prefers the backend's own
/// `message` when Cartivo explained the rejection (e.g. an invalid status
/// transition) and the fixed copy for [error] would be less specific.
class CartivoPosFailure {
  const CartivoPosFailure(this.error, this.message);

  final CartivoPosError error;
  final String message;
}

CartivoPosFailure cartivoPosFailureFrom(Object error) {
  final reason = cartivoPosErrorFrom(error);
  final serverMessage = error is ApiResponseException ? error.serverMessage : '';
  final useServer =
      serverMessage.isNotEmpty &&
      (reason == CartivoPosError.invalidTransition ||
          reason == CartivoPosError.unknown);
  return CartivoPosFailure(reason, useServer ? serverMessage : reason.message);
}

extension CartivoPosErrorRetry on CartivoPosError {
  /// Whether trying the same request again can succeed. A missing order or a
  /// store mismatch never will.
  bool get isRetryable => switch (this) {
    CartivoPosError.unknownOrder ||
    CartivoPosError.orderNotFound ||
    CartivoPosError.merchantMismatch ||
    CartivoPosError.reasonRequired ||
    CartivoPosError.invalidTransition => false,
    _ => true,
  };
}

extension CartivoPosErrorMessage on CartivoPosError {
  String get message => switch (this) {
    CartivoPosError.unauthorized => 'Your Cartivo session expired. Try again.',
    CartivoPosError.merchantMismatch => 'This store doesn\'t match your account.',
    CartivoPosError.unknownOrder => 'This order isn\'t in your recent history.',
    CartivoPosError.orderNotFound => 'Cartivo has no record of this order.',
    CartivoPosError.reasonRequired =>
      'Please give a reason for cancelling this order.',
    CartivoPosError.invalidTransition =>
      "This order can't move to that status.",
    CartivoPosError.serviceUnavailable =>
      'Cartivo is unavailable right now. Try again shortly.',
    CartivoPosError.network => 'No connection. Check your network and try again.',
    CartivoPosError.unknown => 'Something went wrong talking to Cartivo. Try again.',
  };
}
