import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_registration_dto.dart';
import '../../../data/backend_api/schemas/register_device_request.dart';
import '../../../data/backend_api/sources/merchant_devices_api.dart';
import '../../../data/secure_storage/sources/device_token_storage.dart';
import '../../../data/secure_storage/sources/merchant_device_storage.dart';

final merchantDeviceRepositoryProvider = Provider<MerchantDeviceRepository>((
  ref,
) {
  final api = ref.watch(merchantDevicesApiProvider);
  final storage = ref.watch(merchantDeviceStorageProvider);
  final deviceTokenStorage = ref.watch(deviceTokenStorageProvider);
  return MerchantDeviceRepositoryImpl(api, storage, deviceTokenStorage);
});

abstract class MerchantDeviceRepository {
  /// Registers this device with the backend and persists the returned
  /// `device_id` (and `device_secret`, when present) in secure storage,
  /// tagged with the [storeId] it was registered against.
  Future<DeviceRegistrationDto> registerDevice(
    RegisterDeviceRequest request, {
    required String storeId,
  });

  Future<String?> currentDeviceId();

  /// The `store_id` the persisted registration belongs to, if any.
  Future<String?> registeredStoreId();

  /// Forgets the persisted `device_id` / `device_secret` / registered store.
  Future<void> forget();
}

class MerchantDeviceRepositoryImpl implements MerchantDeviceRepository {
  const MerchantDeviceRepositoryImpl(
    this._api,
    this._storage,
    this._deviceTokenStorage,
  );

  final MerchantDevicesApi _api;
  final MerchantDeviceStorage _storage;
  final DeviceTokenStorage _deviceTokenStorage;

  @override
  Future<DeviceRegistrationDto> registerDevice(
    RegisterDeviceRequest request, {
    required String storeId,
  }) async {
    final registration = await _api.registerDevice(request);
    await _storage.writeDeviceId(registration.deviceId);
    final secret = registration.deviceSecret;
    if (secret != null && secret.isNotEmpty) {
      await _storage.writeDeviceSecret(secret);
    }
    await _storage.writeRegisteredStoreId(storeId);
    return registration;
  }

  @override
  Future<String?> currentDeviceId() => _storage.deviceId;

  @override
  Future<String?> registeredStoreId() => _storage.registeredStoreId;

  @override
  Future<void> forget() async {
    await _storage.clear();
    // The cached `/devices/token` bearer is minted from the credentials we
    // just dropped — clear it too so nothing hands out a stale token.
    await _deviceTokenStorage.clear();
  }
}
