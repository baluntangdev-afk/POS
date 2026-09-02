import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_registration_dto.dart';
import '../../../data/backend_api/schemas/register_device_request.dart';
import '../../../data/backend_api/sources/merchant_devices_api.dart';
import '../../../data/secure_storage/sources/merchant_device_storage.dart';

final merchantDeviceRepositoryProvider = Provider<MerchantDeviceRepository>((
  ref,
) {
  final api = ref.watch(merchantDevicesApiProvider);
  final storage = ref.watch(merchantDeviceStorageProvider);
  return MerchantDeviceRepositoryImpl(api, storage);
});

abstract class MerchantDeviceRepository {
  /// Registers this device with the backend and persists the returned
  /// `device_id` (and `device_secret`, when present) in secure storage,
  /// tagged with the [storeId] it was registered against.
  Future<DeviceRegistrationDto> registerDevice(
    RegisterDeviceRequest request, {
    required String storeId,
  });

  /// The `device_id` saved by a previous [registerDevice] call, if any.
  Future<String?> currentDeviceId();

  /// The `store_id` the persisted registration belongs to, if any.
  Future<String?> registeredStoreId();

  /// Forgets the persisted `device_id` / `device_secret` / registered store.
  Future<void> forget();
}

class MerchantDeviceRepositoryImpl implements MerchantDeviceRepository {
  const MerchantDeviceRepositoryImpl(this._api, this._storage);

  final MerchantDevicesApi _api;
  final MerchantDeviceStorage _storage;

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
  Future<void> forget() => _storage.clear();
}
