import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/orders_history_api.dart';
import '../../../data/secure_storage/schemas/webhook_auth_doc.dart';
import '../../../data/secure_storage/sources/webhook_auth_storage.dart';

final webhookAuthRepositoryProvider = Provider<WebhookAuthRepository>((ref) {
  final api = ref.watch(ordersHistoryApiProvider);
  final storage = ref.watch(webhookAuthStorageProvider);
  return WebhookAuthRepositoryImpl(api, storage);
});

abstract class WebhookAuthRepository {
  /// Ensures a usable bearer token is cached for [merchantId], fetching a
  /// fresh one only if none is stored yet, it was issued for a different
  /// merchant, or it has expired. Meant to be called once per connection
  /// cycle (e.g. when the Orders feed connects) rather than per request —
  /// [WebhookTokenInterceptor] handles reactive 401 refreshes in between.
  Future<void> ensureToken(String merchantId);
}

class WebhookAuthRepositoryImpl implements WebhookAuthRepository {
  const WebhookAuthRepositoryImpl(this._api, this._storage);

  final OrdersHistoryApi _api;
  final WebhookAuthStorage _storage;

  @override
  Future<void> ensureToken(String merchantId) async {
    final cached = await _tryLatest();
    final isFresh = cached != null && cached.merchantId == merchantId && cached.expiresAt.isAfter(DateTime.now());
    if (isFresh) return;

    final dto = await _api.fetchToken(merchantId);
    await _storage.write(
      WebhookAuthDoc(
        merchantId: dto.merchantId,
        token: dto.token,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(dto.exp * 1000),
      ),
    );
  }

  Future<WebhookAuthDoc?> _tryLatest() async {
    try {
      return await _storage.latest;
    } catch (_) {
      return null;
    }
  }
}
