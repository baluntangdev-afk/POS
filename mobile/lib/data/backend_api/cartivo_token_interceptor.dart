import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage/sources/cartivo_auth_storage.dart';
import 'api_clients.dart';
import 'sources/cartivo_auth_api.dart';

final cartivoTokenInterceptorProvider = Provider<CartivoTokenInterceptor>((ref) {
  return CartivoTokenInterceptor(
    ref.watch(cartivoAuthStorageProvider),
    ref.watch(cartivoAuthApiProvider),
    ref.watch(ordersAuthRefreshApiClientProvider),
  );
});

/// Attaches the Cartivo bearer token (from `POST /cartivo-auth`) to `/pos/*`
/// requests. On a 401 it mints a fresh token once and retries the request.
class CartivoTokenInterceptor extends QueuedInterceptor {
  CartivoTokenInterceptor(this._storage, this._authApi, this._retryClient);

  final CartivoAuthStorage _storage;
  final CartivoAuthApi _authApi;
  final Dio _retryClient;

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
      return handler.next(err);
    }
    try {
      final dto = await _authApi.authenticate();
      final token = dto.accessToken;
      if (!dto.authenticated || token == null || token.isEmpty) {
        return handler.next(err);
      }
      await _storage.writeAccessToken(token);
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra[_retriedKey] = true;
      return handler.resolve(await _retryClient.fetch<dynamic>(requestOptions));
    } catch (_) {
      // Refresh or retry failed — surface the original 401 so callers keep its slug.
      return handler.next(err);
    }
  }
}
