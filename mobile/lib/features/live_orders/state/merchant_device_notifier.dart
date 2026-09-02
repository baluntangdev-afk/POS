import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../data/backend_api/schemas/device_registration_dto.dart';
import '../../../data/backend_api/schemas/register_device_request.dart';
import '../../settings/state/store_info_notifier.dart';
import '../entities/merchant_device_state.dart';
import '../repositories/merchant_device_repository.dart';
import '../use_cases/device_identity.dart';
import '../use_cases/device_registration_error.dart';

final merchantDeviceNotifierProvider =
    AsyncNotifierProvider<MerchantDeviceNotifier, MerchantDeviceState>(
      MerchantDeviceNotifier.new,
      name: 'merchantDeviceNotifierProvider',
    );

class MerchantDeviceNotifier extends AsyncNotifier<MerchantDeviceState> {
  MerchantDeviceRepository get _repository =>
      ref.read(merchantDeviceRepositoryProvider);

  @override
  Future<MerchantDeviceState> build() async {
    final deviceId = await _repository.currentDeviceId();
    final registeredStoreId = await _repository.registeredStoreId();
    return MerchantDeviceState(
      deviceId: deviceId,
      registeredStoreId: registeredStoreId,
    );
  }

  Future<void> registerIfNeeded({required String name}) async {
    try {
      final loaded = await future;
      if (loaded.isRegistering) return;

      final storeInfo = await ref.read(storeInfoProvider.future);
      final storeId = storeInfo?.storeId.trim() ?? '';
      if (storeId.isEmpty) return;
      if (loaded.isRegistered && loaded.registeredStoreId != storeId) {
        await _repository.forget();
        state = const AsyncData(MerchantDeviceState());
      }

      final request = await ref
          .read(deviceIdentityProvider)
          .describe(name: name);
      await register(request, storeId: storeId);
    } catch (error, stackTrace) {
      debugPrint(
        '[MerchantDevice] registerIfNeeded skipped: $error\n$stackTrace',
      );
    }
  }

  Future<Result<DeviceRegistrationDto, DeviceRegistrationError>> register(
    RegisterDeviceRequest request, {
    required String storeId,
  }) async {
    final current = state.value ?? const MerchantDeviceState();
    // Guard against a double-submit while a request is already in flight.
    if (current.isRegistering) {
      return const Failure(DeviceRegistrationError.rateLimited);
    }
    state = AsyncData(
      MerchantDeviceState(
        deviceId: current.deviceId,
        registeredStoreId: current.registeredStoreId,
        registration: current.registration,
        isRegistering: true,
      ),
    );

    try {
      final registration = await _repository.registerDevice(
        request,
        storeId: storeId,
      );
      state = AsyncData(
        MerchantDeviceState(
          deviceId: registration.deviceId,
          registeredStoreId: storeId,
          registration: registration,
        ),
      );
      return Success(registration);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] register failed: $error\n$stackTrace');
      final reason = deviceRegistrationErrorFrom(error);
      state = AsyncData(
        MerchantDeviceState(
          deviceId: current.deviceId,
          registeredStoreId: current.registeredStoreId,
          registration: current.registration,
          error: reason,
        ),
      );
      return Failure(reason);
    }
  }

  /// Clears the persisted `device_id` (e.g. on sign-out or device reset).
  Future<void> forget() async {
    await _repository.forget();
    state = const AsyncData(MerchantDeviceState());
  }

  /// Re-reads the persisted `device_id` from secure storage.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
