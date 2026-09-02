import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../secure_storage.dart';

final merchantDeviceStorageProvider = Provider<MerchantDeviceStorage>((ref) {
  return MerchantDeviceStorage(ref.watch(secureStorageProvider));
});

/// Persists the identifiers this app needs to register itself with the
/// backend: a stable per-install id (survives restarts, regenerated only on
/// reinstall / storage wipe) and the `device_id` issued by
/// `POST /devices/register`.
class MerchantDeviceStorage {
  MerchantDeviceStorage(this._storage);

  static const _deviceIdKey = 'merchant_device_id';
  static const _deviceSecretKey = 'merchant_device_secret';
  static const _installIdKey = 'merchant_install_id';
  static const _registeredStoreIdKey = 'merchant_registered_store_id';

  final FlutterSecureStorage _storage;

  Future<String?> get deviceId => _storage.read(key: _deviceIdKey);

  Future<void> writeDeviceId(String deviceId) =>
      _storage.write(key: _deviceIdKey, value: deviceId);

  /// The `store_id` this device was last registered against. A registration
  /// is scoped to one merchant/store, so a change here means the device must
  /// re-register.
  Future<String?> get registeredStoreId =>
      _storage.read(key: _registeredStoreIdKey);

  Future<void> writeRegisteredStoreId(String storeId) =>
      _storage.write(key: _registeredStoreIdKey, value: storeId);

  Future<String?> get deviceSecret => _storage.read(key: _deviceSecretKey);

  /// The `device_secret` is returned exactly once (on the 202 response), so
  /// persist it whenever the backend hands one back and never overwrite a
  /// stored secret with null.
  Future<void> writeDeviceSecret(String deviceSecret) =>
      _storage.write(key: _deviceSecretKey, value: deviceSecret);

  /// Returns the stable install id, generating and persisting one on first
  /// call. Not cleared by [clear] — it identifies the install, not the
  /// approval.
  Future<String> ensureInstallId() async {
    final existing = await _storage.read(key: _installIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuidV4();
    await _storage.write(key: _installIdKey, value: generated);
    return generated;
  }

  Future<void> clear() async {
    await _storage.delete(key: _deviceIdKey);
    await _storage.delete(key: _deviceSecretKey);
    await _storage.delete(key: _registeredStoreIdKey);
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
