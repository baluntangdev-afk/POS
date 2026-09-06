import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../config/env_config.dart';

/// Readable request/response logs, only when `ENABLE_LOGGING=true`.
/// Constructed by [ApiClient].
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor()
      : _delegate = PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 100,
        );

  final PrettyDioLogger _delegate;

  bool get _enabled => EnvConfig.enableLogging;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      _delegate.onRequest(options, handler);
    } else {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      _delegate.onResponse(response, handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      _delegate.onError(err, handler);
    } else {
      handler.next(err);
    }
  }
}
