import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../utils/app_logger.dart';

/// The only path from the data layer to the wire.
///
/// Datasource `Impl` methods call:
/// ```dart
/// NetworkHandler.call(request: ..., parser: ...)
///     .fold((f) => throw f.toException(), (r) => r);
/// ```
class NetworkHandler {
  const NetworkHandler._();

  static Future<Either<Failure, T>> call<T>({
    required Future<Response<dynamic>> Function() request,
    required T Function(dynamic data) parser,
  }) async {
    try {
      final res = await request();
      final code = res.statusCode ?? 500;
      if (code >= 200 && code <= 299) {
        return Right(parser(res.data));
      }
      return Left(_mapStatus(code, res.data));
    } on DioException catch (e, s) {
      AppLogger.logError('NetworkHandler', e, s);
      return Left(_mapDio(e));
    } catch (e, s) {
      AppLogger.logError('NetworkHandler', e, s);
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  static Failure _mapStatus(int code, dynamic data) {
    final message = _extractMessage(data);
    return switch (code) {
      401 => const Failure.unauthorized(),
      403 => const Failure.forbidden(),
      404 => const Failure.notFound(),
      422 => Failure.validation(message: message ?? 'Validation failed.'),
      _ => Failure.server(
          statusCode: code,
          message: message ?? 'Something went wrong ($code).',
        ),
    };
  }

  static Failure _mapDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const Failure.network(
          message: 'Could not reach the server. Check your connection.',
        );
      case DioExceptionType.badResponse:
        return _mapStatus(
          e.response?.statusCode ?? 500,
          e.response?.data,
        );
      case DioExceptionType.cancel:
        return const Failure.unexpected(message: 'Request cancelled.');
      case DioExceptionType.badCertificate:
        return const Failure.network(message: 'Insecure server certificate.');
      case DioExceptionType.unknown:
        return Failure.unexpected(message: e.message ?? 'Unexpected error.');
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    return null;
  }
}
