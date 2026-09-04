import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/errors/api_exception.dart';
import '../../../data/backend_api/schemas/device_token_dto.dart';
import '../../../data/backend_api/sources/device_token_api.dart';
import '../../../data/secure_storage/schemas/device_token_doc.dart';
import '../../../data/secure_storage/sources/device_token_storage.dart';
import '../../../data/secure_storage/sources/merchant_device_storage.dart';
import '../use_cases/device_token_error.dart';

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepositoryImpl(
    ref.watch(deviceTokenApiProvider),
    ref.watch(deviceTokenStorageProvider),
    ref.watch(merchantDeviceStorageProvider),
  );
});

/// Small clock skew allowed before a cached token is treated as expired, so a
/// token that dies mid-handshake isn't handed out.
const _expiryGuard = Duration(seconds: 30);

abstract class DeviceTokenRepository {
  /// Returns a valid `/devices/token` bearer for [merchantId], minting a fresh
  /// one only when the cached token is missing, for a different merchant, or
  /// (nearly) expired.
  ///
  /// Throws [DeviceTokenException] — `noDeviceCredentials` when the device
  /// hasn't registered, or the mapped backend rejection otherwise.
  Future<String> ensureToken(String merchantId);

  /// Unconditionally mints a fresh token for [merchantId] and caches it,
  /// replacing any stored one. Throws [DeviceTokenException] on failure.
  Future<String> refreshToken(String merchantId);

  /// Forgets the cached token so the next [ensureToken] re-mints. Used on a
  /// WebSocket auth rejection and when the device credentials are cleared.
  Future<void> invalidate();
}

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  const DeviceTokenRepositoryImpl(
    this._api,
    this._storage,
    this._deviceStorage,
  );

  final DeviceTokenApi _api;
  final DeviceTokenStorage _storage;
  final MerchantDeviceStorage _deviceStorage;

  @override
  Future<String> ensureToken(String merchantId) async {
    final cached = await _tryLatest();
    final isFresh =
        cached != null &&
        cached.merchantId == merchantId &&
        cached.expiresAt.isAfter(DateTime.now().add(_expiryGuard));
    if (isFresh) return cached.token;

    return refreshToken(merchantId);
  }

  @override
  Future<String> refreshToken(String merchantId) async {
    final deviceId = await _deviceStorage.deviceId;
    final deviceSecret = await _deviceStorage.deviceSecret;
    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceSecret == null ||
        deviceSecret.isEmpty) {
      throw DeviceTokenException(
        DeviceTokenError.noDeviceCredentials,
        DeviceTokenError.noDeviceCredentials.message,
      );
    }

    final DeviceTokenDto dto;
    try {
      dto = await _api.fetchToken(
        deviceId: deviceId,
        deviceSecret: deviceSecret,
      );
    } on ApiException catch (error) {
      final reason = deviceTokenErrorFrom(error);
      throw DeviceTokenException(
        reason,
        deviceTokenMessageFrom(error, reason),
      );
    }

    await _storage.write(
      DeviceTokenDoc(
        merchantId: dto.merchantId,
        token: dto.token,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(dto.exp * 1000),
      ),
    );
    return dto.token;
  }

  @override
  Future<void> invalidate() => _storage.clear();

  Future<DeviceTokenDoc?> _tryLatest() async {
    try {
      return await _storage.latest;
    } catch (_) {
      return null;
    }
  }
}
