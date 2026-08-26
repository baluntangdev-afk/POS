import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/missing_record_exception.dart';
import '../schemas/webhook_auth_doc.dart';
import '../secure_storage.dart';

final webhookAuthStorageProvider = Provider<WebhookAuthStorage>((ref) {
  return WebhookAuthStorage(ref.watch(secureStorageProvider));
});

/// Caches the bearer token issued by the webhook-receiver's `/auth/token`,
/// keyed separately from [AuthDoc] so writing one can never clobber the
/// other in the shared secure-storage backend.
class WebhookAuthStorage {
  WebhookAuthStorage(this._storage);

  static const _key = 'webhook_auth_doc';

  final FlutterSecureStorage _storage;

  Future<WebhookAuthDoc> get latest async {
    final stored = await _storage.read(key: _key);
    if (stored == null) throw MissingRecordException('No saved webhook token.');
    return WebhookAuthDoc.fromJson(stored);
  }

  Future<void> write(WebhookAuthDoc document) async {
    await _storage.write(key: _key, value: document.toJson());
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
