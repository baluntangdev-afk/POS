import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/data/backend_api/sources/auth_api.dart';

import '../../../data/backend_api/errors/api_exception.dart';
import '../../../data/backend_api/schemas/webhook_token_dto.dart';
import '../../../data/secure_storage/schemas/webhook_auth_doc.dart';
import '../../../data/secure_storage/sources/webhook_auth_storage.dart';
import '../use_cases/webhook_auth_error.dart';

final webhookAuthRepositoryProvider = Provider<WebhookAuthRepository>((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(webhookAuthStorageProvider);
  return WebhookAuthRepositoryImpl(api, storage);
});

abstract class WebhookAuthRepository {
  /// Fetches a token for [merchantId] only when the cached one is missing,
  /// for a different merchant, or expired.
  ///
  /// Throws [WebhookAuthException] when the backend rejects the request
  /// (e.g. a wrong `WEBHOOK_SECRET`).
  Future<void> ensureToken(String merchantId);

  /// Unconditionally mints a fresh token for [merchantId] and persists it as
  /// the active bearer token, replacing any cached one. Use this when the
  /// merchant/store id has changed.
  ///
  /// Throws [WebhookAuthException] on a rejected request, same as
  /// [ensureToken].
  Future<void> refreshToken(String merchantId);
}

class WebhookAuthRepositoryImpl implements WebhookAuthRepository {
  const WebhookAuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final WebhookAuthStorage _storage;

  @override
  Future<void> ensureToken(String merchantId) async {
    final cached = await _tryLatest();
    final isFresh =
        cached != null &&
        cached.merchantId == merchantId &&
        cached.expiresAt.isAfter(DateTime.now());
    if (isFresh) return;

    await refreshToken(merchantId);
  }

  @override
  Future<void> refreshToken(String merchantId) async {
    final WebhookTokenDto dto;
    try {
      dto = await _api.fetchToken(merchantId);
    } on ApiException catch (error) {
      final reason = webhookAuthErrorFrom(error);
      throw WebhookAuthException(
        reason,
        webhookAuthMessageFrom(error, reason),
      );
    }
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
