import '../../../../core/storage/merchant_device_storage.dart';
import '../../../merchant/data/merchant_api.dart';

/// 30-second buffer — don't hand out a token that expires mid-handshake.
const _expiryGuard = Duration(seconds: 30);

/// Manages the `/devices/token` bearer JWT used to authenticate the WebSocket
/// handshake. Caches the token in [MerchantDeviceStorage] and re-mints only
/// when the cached one is missing, belongs to a different merchant, or is
/// about to expire.
class DeviceTokenRepository {
  const DeviceTokenRepository(this._api, this._storage);

  final MerchantApi _api;
  final MerchantDeviceStorage _storage;

  /// Returns a valid device token for [merchantId], minting a fresh one only
  /// when necessary. Throws if device credentials are missing.
  Future<String> ensureToken(String merchantId) async {
    final cachedToken = await _storage.deviceWsToken;
    final cachedExp = await _storage.deviceWsTokenExp;
    final cachedMerchantId = await _storage.deviceWsTokenMerchantId;

    if (cachedToken != null &&
        cachedExp != null &&
        cachedMerchantId == merchantId) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(cachedExp * 1000);
      if (expiresAt.isAfter(DateTime.now().add(_expiryGuard))) {
        return cachedToken;
      }
    }

    return refreshToken(merchantId);
  }

  /// Unconditionally mints a fresh token and caches it.
  Future<String> refreshToken(String merchantId) async {
    final deviceId = await _storage.deviceId;
    final deviceSecret = await _storage.deviceSecret;

    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceSecret == null ||
        deviceSecret.isEmpty) {
      throw Exception('Device credentials not found — device may not be registered.');
    }

    final dto = await _api.fetchDeviceToken(
      deviceId: deviceId,
      deviceSecret: deviceSecret,
    );

    await _storage.writeDeviceWsToken(dto.token, dto.exp, dto.merchantId);
    return dto.token;
  }

  /// Clears the cached token so the next [ensureToken] re-mints. Call on
  /// WebSocket auth rejection (401/403).
  Future<void> invalidate() => _storage.clearDeviceWsToken();
}
