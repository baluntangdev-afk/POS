import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage/sources/cartivo_auth_storage.dart';

final cartivoTokenInterceptorProvider = Provider<CartivoTokenInterceptor>((ref) {
  final authStorage = ref.watch(cartivoAuthStorageProvider);
  return CartivoTokenInterceptor(authStorage);
});

/// Attaches the stored Cartivo bearer token to outgoing requests. On a 401
/// response the stored session is cleared; [CartivoAuthStorage.stored] then
/// emits `null`, which the UI listens to in order to route back to the
/// Cartivo login screen (see `CartivoHomeScreen`).
class CartivoTokenInterceptor extends Interceptor {
  CartivoTokenInterceptor(this._storage);

  final CartivoAuthStorage _storage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final doc = await _storage.latestOrNull;
    if (doc != null) {
      options.headers['Authorization'] = 'Bearer ${doc.token}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.clear();
    }
    handler.next(err);
  }
}
