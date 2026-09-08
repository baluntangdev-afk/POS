import '../../../../core/storage/merchant_device_storage.dart';
import '../../../merchant/data/merchant_api.dart';

/// Mints the `POST /devices/token` bearer JWT used to authenticate the
/// live-orders WebSocket handshake.
///
/// The token is **not** cached across launches — [mint] is called on every
/// connect attempt (see the launch-auth-chain spec). The minted token is still
/// written to [MerchantDeviceStorage] so [invalidate] can clear it on a
/// handshake rejection and for parity with `mobile/`.
class DeviceTokenRepository {
  const DeviceTokenRepository(this._api, this._storage);

  final MerchantApi _api;
  final MerchantDeviceStorage _storage;

  /// Mints a fresh device token.
  ///
  /// [webhookToken] is the `/auth/token` JWT, sent as the bearer on
  /// `POST /devices/token`. [deviceId] / [deviceSecret] come from the
  /// `/devices/register` response; when [deviceSecret] is null or empty the
  /// stored secret (from a prior `202` enrolment) is used instead. Throws when
  /// no secret is available from either source.
  Future<String> mint({
    required String webhookToken,
    required String deviceId,
    String? deviceSecret,
  }) async {
    final secret = (deviceSecret != null && deviceSecret.isNotEmpty)
        ? deviceSecret
        : await _storage.deviceSecret;

    if (deviceId.isEmpty || secret == null || secret.isEmpty) {
      throw Exception(
        'Device credentials unavailable for POST /devices/token',
      );
    }

    final dto = await _api.fetchDeviceToken(
      deviceId: deviceId,
      deviceSecret: secret,
      token: webhookToken,
    );

    await _storage.writeDeviceWsToken(dto.token, dto.exp, dto.merchantId);
    return dto.token;
  }

  /// Clears the cached WS token. Call on a 401/403 WebSocket handshake
  /// rejection so the next [mint] result fully replaces it.
  Future<void> invalidate() => _storage.clearDeviceWsToken();
}
