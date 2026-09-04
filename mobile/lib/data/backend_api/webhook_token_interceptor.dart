import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/backend_api/sources/auth_api.dart';

import '../../config/environment/app_env.dart';
import '../secure_storage/schemas/webhook_auth_doc.dart';
import '../secure_storage/sources/webhook_auth_storage.dart';
import 'api_clients.dart';

final webhookTokenInterceptorProvider = Provider<WebhookTokenInterceptor>((ref) {
  final storage = ref.watch(webhookAuthStorageProvider);
  final refreshClient = ref.watch(ordersAuthRefreshApiClientProvider);
  final env = ref.watch(appEnvProvider);
  return WebhookTokenInterceptor(storage, refreshClient, env);
});

class WebhookTokenInterceptor extends QueuedInterceptor {
  WebhookTokenInterceptor(this._storage, this._refreshClient, this._env);

  final WebhookAuthStorage _storage;
  final Dio _refreshClient;
  final AppEnv _env;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _latestToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final DioException(:response, :requestOptions) = err;
    if (response?.statusCode != 401) {
      return handler.next(err);
    }
    try {
      final WebhookAuthDoc(:merchantId) = await _storage.latest;
      final refreshed = await _refreshToken(merchantId);
      requestOptions.headers['Authorization'] = 'Bearer ${refreshed.token}';
      final retryResponse = await _refreshClient.fetch<dynamic>(requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      return handler.reject(DioException(requestOptions: err.requestOptions, error: e));
    }
  }

  Future<String?> _latestToken() async {
    try {
      final WebhookAuthDoc(:token) = await _storage.latest;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<WebhookAuthDoc> _refreshToken(String merchantId) async {
    final dto = await AuthApi(_refreshClient, _env).fetchToken(merchantId);
    final doc = WebhookAuthDoc(
      merchantId: dto.merchantId,
      token: dto.token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(dto.exp * 1000),
    );
    await _storage.write(doc);
    return doc;
  }
}
