import 'dart:math';

import 'package:injectable/injectable.dart';

import 'secure_storage.dart';

/// Persists webhook-auth token and device-registration credentials in
/// encrypted storage. Separate from the user auth token in [SecureStorage].
@lazySingleton
class MerchantDeviceStorage {
  MerchantDeviceStorage(this._storage);

  final SecureStorage _storage;

  static const _tokenKey = 'merchant_webhook_token';
  static const _tokenExpKey = 'merchant_webhook_token_exp';
  static const _tokenMerchantIdKey = 'merchant_webhook_token_merchant_id';
  static const _deviceIdKey = 'merchant_device_id';
  static const _deviceSecretKey = 'merchant_device_secret';
  static const _installIdKey = 'merchant_install_id';
  static const _registeredMerchantIdKey = 'merchant_registered_merchant_id';
  static const _deviceStatusKey = 'merchant_device_status';

  // Device WS token — short-lived JWT from POST /devices/token for WS bearer auth
  static const _deviceWsTokenKey = 'merchant_device_ws_token';
  static const _deviceWsTokenExpKey = 'merchant_device_ws_token_exp';
  static const _deviceWsTokenMerchantIdKey = 'merchant_device_ws_token_merchant_id';

  // ── Token ────────────────────────────────────────────────────────────────

  Future<String?> get token => _storage.read(_tokenKey);

  Future<int?> get tokenExp async {
    final raw = await _storage.read(_tokenExpKey);
    return raw != null ? int.tryParse(raw) : null;
  }

  /// The `merchant_id` the stored [token] is scoped to. A webhook JWT only
  /// works for the merchant it was minted for, so callers must re-mint when
  /// this no longer matches the merchant they're acting as.
  Future<String?> get tokenMerchantId => _storage.read(_tokenMerchantIdKey);

  Future<void> writeToken(String token, int exp, String merchantId) async {
    await _storage.write(_tokenKey, token);
    await _storage.write(_tokenExpKey, exp.toString());
    await _storage.write(_tokenMerchantIdKey, merchantId);
  }

  // ── Device credentials ───────────────────────────────────────────────────

  Future<String?> get deviceId => _storage.read(_deviceIdKey);

  Future<String?> get deviceSecret => _storage.read(_deviceSecretKey);

  Future<String?> get registeredMerchantId =>
      _storage.read(_registeredMerchantIdKey);

  Future<void> writeDeviceId(String id) => _storage.write(_deviceIdKey, id);

  /// The secret is returned exactly once (202). Only write when present.
  Future<void> writeDeviceSecret(String secret) =>
      _storage.write(_deviceSecretKey, secret);

  Future<void> writeRegisteredMerchantId(String merchantId) =>
      _storage.write(_registeredMerchantIdKey, merchantId);

  /// Last device-enrollment status seen from `POST /devices/register`
  /// (`pending` | `approved` | `deactivated` | ...). Read synchronously on
  /// launch as an optimistic gate for the order feed.
  Future<String?> get deviceStatus => _storage.read(_deviceStatusKey);

  Future<void> writeDeviceStatus(String status) =>
      _storage.write(_deviceStatusKey, status);

  // ── Device WS Token ──────────────────────────────────────────────────────

  Future<String?> get deviceWsToken => _storage.read(_deviceWsTokenKey);

  Future<int?> get deviceWsTokenExp async {
    final raw = await _storage.read(_deviceWsTokenExpKey);
    return raw != null ? int.tryParse(raw) : null;
  }

  Future<String?> get deviceWsTokenMerchantId =>
      _storage.read(_deviceWsTokenMerchantIdKey);

  Future<void> writeDeviceWsToken(
    String token,
    int exp,
    String merchantId,
  ) async {
    await _storage.write(_deviceWsTokenKey, token);
    await _storage.write(_deviceWsTokenExpKey, exp.toString());
    await _storage.write(_deviceWsTokenMerchantIdKey, merchantId);
  }

  Future<void> clearDeviceWsToken() async {
    await _storage.delete(_deviceWsTokenKey);
    await _storage.delete(_deviceWsTokenExpKey);
    await _storage.delete(_deviceWsTokenMerchantIdKey);
  }

  // ── Install ID ───────────────────────────────────────────────────────────

  /// Stable per-install UUID. Generated once on first call; never cleared.
  Future<String> ensureInstallId() async {
    final existing = await _storage.read(_installIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuidV4();
    await _storage.write(_installIdKey, id);
    return id;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Wipes token + device credentials when the merchant changes. Install ID
  /// is intentionally preserved — it identifies the app install, not the
  /// merchant association.
  Future<void> clearForMerchantChange() async {
    await _storage.delete(_tokenKey);
    await _storage.delete(_tokenExpKey);
    await _storage.delete(_tokenMerchantIdKey);
    await _storage.delete(_deviceIdKey);
    await _storage.delete(_deviceSecretKey);
    await _storage.delete(_registeredMerchantIdKey);
    await _storage.delete(_deviceStatusKey);
    await _storage.delete(_deviceWsTokenKey);
    await _storage.delete(_deviceWsTokenExpKey);
    await _storage.delete(_deviceWsTokenMerchantIdKey);
  }

  static String _uuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
