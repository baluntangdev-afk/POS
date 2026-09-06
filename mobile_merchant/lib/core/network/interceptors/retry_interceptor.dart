import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

/// Retries pure connection errors up to [AppConfig.maxNetworkRetries] times.
/// Does not retry once the server has actually responded. Constructed by
/// [ApiClient].
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const String _retryCountKey = 'retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra[_retryCountKey] as int? ?? 0) + 1;
    if (attempt > AppConfig.maxNetworkRetries) {
      return handler.next(err);
    }

    AppLogger.logWarning(
      'RetryInterceptor: retry $attempt/${AppConfig.maxNetworkRetries} '
      'for ${err.requestOptions.uri}',
    );

    final options = err.requestOptions
      ..extra[_retryCountKey] = attempt;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetryable(DioException err) =>
      err.type == DioExceptionType.connectionError ||
      err.type == DioExceptionType.connectionTimeout;
}
