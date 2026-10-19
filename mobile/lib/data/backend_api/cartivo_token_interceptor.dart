import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage/sources/cartivo_auth_storage.dart';
import 'api_clients.dart';
import 'errors/api_exception.dart';
import 'session_expired.dart';
import 'sources/cartivo_auth_api.dart';

final cartivoTokenInterceptorProvider = Provider<CartivoTokenInterceptor>((ref) {
  return CartivoTokenInterceptor(
    ref.watch(cartivoAuthStorageProvider),
    ref.watch(cartivoAuthApiProvider),
    ref.watch(ordersAuthRefreshApiClientProvider),
    onSessionExpired: ref.watch(sessionExpiredReporterProvider),
  );
});

/// Attaches the Cartivo bearer token (from `POST /cartivo-auth`) to `/pos/*`
/// requests. On a 401 it mints a fresh token once and retries the request.
class CartivoTokenInterceptor extends QueuedInterceptor {
  CartivoTokenInterceptor(
    this._storage,
    this._authApi,
    this._retryClient, {
    required void Function() onSessionExpired,
  }) : _onSessionExpired = onSessionExpired;

  final CartivoAuthStorage _storage;
  final CartivoAuthApi _authApi;
  final Dio _retryClient;
  final void Function() _onSessionExpired;

  static const _retriedKey = 'cartivo_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    if (err.response?.statusCode != 401 || requestOptions.extra[_retriedKey] == true) {
      return _handleFailure(err, handler);
    }
    try {
      final dto = await _authApi.authenticate();
      final token = dto.accessToken;
      if (!dto.authenticated || token == null || token.isEmpty) {
        return _handleFailure(err, handler);
      }
      await _storage.writeAccessToken(token);
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra[_retriedKey] = true;
      return handler.resolve(await _retryClient.fetch<dynamic>(requestOptions));
    } catch (e) {
      // Refresh or retry failed — surface the original 401 so callers keep its slug.
      // A transport error (offline, timeout) says nothing about the session, so don't log out.
      if (ApiException.from(e) is NetworkException) return handler.next(err);
      return _handleFailure(err, handler);
    }
  }

  /// A 401 we could not recover from. When it is the session token itself that
  /// was rejected (`invalid_or_expired_token`), drop the stale token and signal
  /// the app to force a re-login. Otherwise just pass the error on.
  Future<void> _handleFailure(DioException err, ErrorInterceptorHandler handler) async {
    if (isExpiredSessionError(err)) {
      try {
        await _storage.clear();
      } catch (_) {
        // Best-effort — never let a storage failure block the logout signal.
      }
      _onSessionExpired();
    }
    handler.next(err);
  }
}
