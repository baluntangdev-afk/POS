import 'package:dio/dio.dart';

enum OrdersServerCheckFailure { invalidAddress, timeout, unreachable }

class OrdersServerCheckException implements Exception {
  const OrdersServerCheckException(this.reason);

  final OrdersServerCheckFailure reason;

  String get message => switch (reason) {
    OrdersServerCheckFailure.invalidAddress =>
      'Enter a full address starting with http:// or https://',
    OrdersServerCheckFailure.timeout =>
      'No response after 8 seconds. Check the address and that the phone is '
          'online, then try again.',
    OrdersServerCheckFailure.unreachable =>
      'The server refused the connection or couldn\'t be found. Check the '
          'address and try again.',
  };

  @override
  String toString() => 'OrdersServerCheckException($reason)';
}

const _schemes = {'http', 'https'};

/// Trims whitespace and trailing slashes so the live feed's `'$base/ws'`
/// join doesn't produce `//ws`.
String normalizeOrdersServerUrl(String raw) =>
    raw.trim().replaceFirst(RegExp(r'/+$'), '');

/// Proves [baseUrl] points at a server that answers, with a plain HTTP GET
/// to its root. Any HTTP response (including 401/404) counts as reachable:
/// the login screen has no webhook or device token yet, so an authenticated
/// check (e.g. the live-feed WebSocket, which needs an approved-device
/// bearer) would reject a correct address. Only DNS/TLS/refused/timeout
/// failures count. Throws [OrdersServerCheckException] on failure.
Future<void> checkOrdersServerConnection(
  String baseUrl, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || !_schemes.contains(uri.scheme) || uri.host.isEmpty) {
    throw const OrdersServerCheckException(
      OrdersServerCheckFailure.invalidAddress,
    );
  }

  final dio = Dio(
    BaseOptions(
      connectTimeout: timeout,
      sendTimeout: timeout,
      receiveTimeout: timeout,
      validateStatus: (_) => true,
    ),
  );
  try {
    await dio.getUri<void>(
      uri,
      options: Options(responseType: ResponseType.plain),
    );
  } on DioException catch (e) {
    throw OrdersServerCheckException(switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => OrdersServerCheckFailure.timeout,
      _ => OrdersServerCheckFailure.unreachable,
    });
  } finally {
    dio.close(force: true);
  }
}
