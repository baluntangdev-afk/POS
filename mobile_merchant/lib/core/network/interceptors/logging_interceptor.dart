import 'package:dio/dio.dart';

import '../../utils/app_logger.dart';
import '../models/network_log_entry.dart';

/// Logs every request, response, and error as a [NetworkLogEntry].
/// Filtering is handled by [AppLogger]'s [_EnvFilter].
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.logDebug(
      RequestEntry(
        method: options.method,
        uri: options.uri,
        headers: Map<String, dynamic>.from(options.headers),
        body: options.data,
      ).toString(),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.logDebug(
      ResponseEntry(
        statusCode: response.statusCode ?? 0,
        uri: response.requestOptions.uri,
        body: response.data,
      ).toString(),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final entry = ErrorEntry(
      method: err.requestOptions.method,
      uri: err.requestOptions.uri,
      kind: NetworkErrorKind.from(err.type),
      statusCode: err.response?.statusCode,
      message: err.message,
      responseBody: err.response?.data,
    );
    AppLogger.logError('LoggingInterceptor', entry);
    handler.next(err);
  }
}
