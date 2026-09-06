import '../entities/device_registration.dart';
import '../entities/merchant.dart';
import '../entities/webhook_token.dart';

abstract interface class MerchantRepository {
  Future<Merchant?> getMerchant();

  Future<void> createMerchant({
    required String merchantId,
    required String merchantName,
  });

  Future<void> updateMerchant({
    required int id,
    required String merchantId,
    required String merchantName,
  });

  /// Fetches a webhook token, registers the device, and persists the
  /// resulting [WebhookToken] and [DeviceRegistration] to secure storage.
  Future<void> activateDevice(String merchantId);

  /// Fetches a fresh webhook token for [merchantId] and persists it.
  /// Used to refresh credentials on app launch without re-registering.
  Future<void> refreshToken(String merchantId);

  /// Wipes all device credentials (token, device_id, device_secret) without
  /// touching the stable install_id.
  Future<void> clearDeviceCredentials();
}
