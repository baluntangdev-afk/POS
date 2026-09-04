import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../schemas/device_token_doc.dart';
import '../secure_storage.dart';

final deviceTokenStorageProvider = Provider<DeviceTokenStorage>((ref) {
  return DeviceTokenStorage(ref.watch(secureStorageProvider));
});

/// Caches the bearer token issued by the webhook-receiver's `/devices/token`.
class DeviceTokenStorage {
  DeviceTokenStorage(this._storage);

  static const _key = 'device_token_doc';

  final FlutterSecureStorage _storage;

  Future<DeviceTokenDoc> get latest async {
    final stored = await _storage.read(key: _key);
    if (stored == null) throw StateError('No saved device token.');
    return DeviceTokenDoc.fromJson(stored);
  }

  Future<void> write(DeviceTokenDoc document) async {
    await _storage.write(key: _key, value: document.toJson());
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
