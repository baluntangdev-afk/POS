import 'dart:convert';

import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _fromDio(error);
    if (error is FormatException) {
      return ApiDecodingException(error.message);
    }
    return ApiUnknownException(error.toString());
  }

  static ApiException _fromDio(DioException error) {
    final wrapped = error.error;
    if (wrapped is ApiException) return wrapped;

    final response = error.response;
    if (response == null) {
      return NetworkException(error.message ?? 'The request could not be sent.');
    }

    final envelope = _ErrorEnvelope.tryParse(response.data);
    return ApiResponseException(
      statusCode: response.statusCode,
      code: envelope?.code ?? '',
      serverMessage: envelope?.message ?? '',
    );
  }
}

final class NetworkException extends ApiException {
  const NetworkException(super.message);
}

final class ApiResponseException extends ApiException {
  ApiResponseException({
    required this.statusCode,
    required this.code,
    this.serverMessage = '',
  }) : super(
         serverMessage.isNotEmpty
             ? serverMessage
             : 'The request failed${statusCode == null ? '' : ' ($statusCode)'}.',
       );

  /// The HTTP status, when known.
  final int? statusCode;

  /// The machine-readable `error` slug, e.g. `invalid_webhook_secret`. Empty
  /// when the body carried no `error` field.
  final String code;

  /// The backend's `message` string, verbatim. Empty when the response body
  /// carried none.
  final String serverMessage;

  /// Whether the backend named an `error` slug callers can branch on.
  bool get hasCode => code.isNotEmpty;
}

/// A 2xx response whose body could not be parsed into the expected shape.
final class ApiDecodingException extends ApiException {
  const ApiDecodingException(super.message);
}

/// Anything else thrown from within an API call.
final class ApiUnknownException extends ApiException {
  const ApiUnknownException(super.message);
}

/// The `{ error, message }` shape shared by every orders-events failure.
class _ErrorEnvelope {
  const _ErrorEnvelope(this.code, this.message);

  final String? code;
  final String? message;

  static _ErrorEnvelope? tryParse(Object? data) {
    final map = _asMap(data);
    if (map == null) return null;
    final code = map['error'];
    final message = map['message'];
    if (code is! String && message is! String) return null;
    return _ErrorEnvelope(
      code is String ? code : null,
      message is String ? message : null,
    );
  }

  static Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}
