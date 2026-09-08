import '../entities/device_registration.dart';
import '../entities/merchant.dart';

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

  Future<DeviceRegistration> activateDevice(String merchantId);

  Future<DeviceRegistration> syncDeviceRegistration();

  /// Returns a webhook JWT scoped to [merchantId], minting a fresh one when the
  /// stored token is missing, near expiry, or scoped to a different merchant.
  ///
  /// A webhook JWT only authorises the merchant it was issued for, so every
  /// caller acting as a specific merchant must go through this rather than
  /// reading the stored token directly — otherwise a merchant switch leaves the
  /// previous merchant's token in place and the backend rejects the request
  /// ("merchant_id does not match the merchant this token is scoped to").
  Future<String> ensureWebhookToken(String merchantId);

  Future<void> refreshToken(String merchantId);

  Future<void> clearDeviceCredentials();
}
