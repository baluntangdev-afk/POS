import 'package:dio/dio.dart';

import '../../auth/session_expired_notifier.dart';
import '../../config/app_config.dart';
import '../../storage/secure_storage.dart';
import '../../utils/app_logger.dart';
import '../api_endpoints.dart';

/// Attaches the bearer token to every request and turns a stray 401 into a
/// session-expiry signal. Constructed by [ApiClient].
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._sessionExpired);

  final SecureStorage _storage;
  final SessionExpiredNotifier _sessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.read(AppConfig.authTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e, s) {
      // A stuck keystore must not hang the request.
      AppLogger.logError('AuthInterceptor.onRequest', e, s);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isLoginCall = err.requestOptions.path.contains(ApiEndpoints.login);
    if (err.response?.statusCode == 401 && !isLoginCall) {
      // Guard against stale in-flight 401s after an explicit logout.
      final token = await _safeReadToken();
      if (token != null && token.isNotEmpty) {
        _sessionExpired.signalExpired();
      }
    }
    handler.next(err);
  }

  Future<String?> _safeReadToken() async {
    try {
      return await _storage.read(AppConfig.authTokenKey);
    } catch (_) {
      return null;
    }
  }
}
