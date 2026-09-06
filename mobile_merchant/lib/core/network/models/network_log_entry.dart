import 'package:dio/dio.dart';

/// Classifies a [DioException] into a human-readable category.
enum NetworkErrorKind {
  connectionTimeout('Connection timed out'),
  sendTimeout('Send timed out'),
  receiveTimeout('Receive timed out'),
  connectionError('Could not reach server'),
  badResponse('Server returned an error response'),
  cancelled('Request was cancelled'),
  badCertificate('Invalid server certificate'),
  unknown('Unknown network error');

  const NetworkErrorKind(this.description);

  final String description;

  static NetworkErrorKind from(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout => connectionTimeout,
        DioExceptionType.sendTimeout => sendTimeout,
        DioExceptionType.receiveTimeout => receiveTimeout,
        DioExceptionType.connectionError => connectionError,
        DioExceptionType.transformTimeout => connectionError,
        DioExceptionType.badResponse => badResponse,
        DioExceptionType.cancel => cancelled,
        DioExceptionType.badCertificate => badCertificate,
        DioExceptionType.unknown => unknown,
      };
}

/// Structured log entries produced by [LoggingInterceptor].
sealed class NetworkLogEntry {
  const NetworkLogEntry();
}

final class RequestEntry extends NetworkLogEntry {
  const RequestEntry({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, dynamic> headers;
  final Object? body;

  @override
  String toString() {
    final buf = StringBuffer('→ $method $uri\nHeaders: $headers');
    if (body != null) buf.write('\nBody: $body');
    return buf.toString();
  }
}

final class ResponseEntry extends NetworkLogEntry {
  const ResponseEntry({
    required this.statusCode,
    required this.uri,
    this.body,
  });

  final int statusCode;
  final Uri uri;
  final Object? body;

  @override
  String toString() => '← $statusCode $uri\nBody: $body';
}

final class ErrorEntry extends NetworkLogEntry {
  const ErrorEntry({
    required this.method,
    required this.uri,
    required this.kind,
    this.statusCode,
    this.message,
    this.responseBody,
  });

  final String method;
  final Uri uri;
  final NetworkErrorKind kind;
  final int? statusCode;
  final String? message;
  final Object? responseBody;

  @override
  String toString() {
    final buf = StringBuffer('✗ $method $uri\n')
      ..write('Kind: ${kind.name} — ${kind.description}');
    if (statusCode != null) buf.write('\nStatus: $statusCode');
    if (message != null) buf.write('\nMessage: $message');
    if (responseBody != null) buf.write('\nResponse: $responseBody');
    return buf.toString();
  }
}
