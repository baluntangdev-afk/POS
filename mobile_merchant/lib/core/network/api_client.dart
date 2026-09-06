import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../auth/session_expired_notifier.dart';
import '../config/app_config.dart';
import '../config/env_config.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Owns the single [Dio] instance and wires its interceptors in order:
///
///   AuthInterceptor → LoggingInterceptor → RetryInterceptor
@lazySingleton
class ApiClient {
  ApiClient(this._storage, this._sessionExpired) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_storage, _sessionExpired),
      LoggingInterceptor(),
      RetryInterceptor(_dio),
    ]);
  }

  final SecureStorage _storage;
  final SessionExpiredNotifier _sessionExpired;

  late final Dio _dio;

  Dio get dio => _dio;

  /// Point the client at a custom endpoint at runtime (used by SettingsService).
  void updateBaseUrl(String url) => _dio.options.baseUrl = url;
}
