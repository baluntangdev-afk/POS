import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/errors/api_exception.dart';
import '../../../data/backend_api/schemas/webhook_token_dto.dart';
import '../../../data/backend_api/sources/orders_auth_api.dart';
import '../../../data/secure_storage/schemas/webhook_auth_doc.dart';
import '../../../data/secure_storage/sources/webhook_auth_storage.dart';
import '../use_cases/webhook_auth_error.dart';

final webhookAuthRepositoryProvider = Provider<WebhookAuthRepository>((ref) {
  final api = ref.watch(ordersAuthApiProvider);
  final storage = ref.watch(webhookAuthStorageProvider);
  return WebhookAuthRepositoryImpl(api, storage);
});

abstract class WebhookAuthRepository {
  /// Ensures a usable bearer token is cached for [merchantId], fetching a
  /// fresh one only if none is stored yet, it was issued for a different
  /// merchant, or it has expired. Meant to be called once per connection
  /// cycle (e.g. when the Orders feed connects) rather than per request —
  /// `WebhookTokenInterceptor` handles reactive 401 refreshes in between.
  ///
  /// Throws [WebhookAuthException] when the backend rejects the request
  /// (e.g. a wrong `WEBHOOK_SECRET`, or an unknown merchant).
  Future<void> ensureToken(String merchantId);

  /// Unconditionally mints a fresh token for [merchantId] and persists it as
  /// the active bearer token, replacing any cached one. Use this when the
  /// Kiosk ID has changed — succeeding is what verifies it as a known
  /// merchant.
  ///
  /// Returns the `merchant_name` the backend resolved for [merchantId], or
  /// `null` when it did not send one.
  ///
  /// Throws [WebhookAuthException] on a rejected request, same as
  /// [ensureToken].
  Future<String?> refreshToken(String merchantId);
}

class WebhookAuthRepositoryImpl implements WebhookAuthRepository {
  const WebhookAuthRepositoryImpl(this._api, this._storage);

  final OrdersAuthApi _api;
  final WebhookAuthStorage _storage;

  @override
  Future<void> ensureToken(String merchantId) async {
    final cached = await _tryLatest();
    final isFresh = cached != null && cached.merchantId == merchantId && cached.expiresAt.isAfter(DateTime.now());
    if (isFresh) return;

    await refreshToken(merchantId);
  }

  @override
  Future<String?> refreshToken(String merchantId) async {
    final WebhookTokenDto dto;
    try {
      dto = await _api.fetchToken(merchantId);
    } on ApiException catch (error) {
      final reason = webhookAuthErrorFrom(error);
      throw WebhookAuthException(reason, webhookAuthMessageFrom(error, reason));
    }
    await _storage.write(
      WebhookAuthDoc(
        merchantId: dto.merchantId,
        token: dto.token,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(dto.exp * 1000),
      ),
    );
    return dto.merchantName;
  }

  Future<WebhookAuthDoc?> _tryLatest() async {
    try {
      return await _storage.latest;
    } catch (_) {
      return null;
    }
  }
}
