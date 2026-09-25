import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_registration_dto.dart';
import '../../../data/backend_api/schemas/register_device_request.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../menu/state/pos_terminal_notifier.dart';
import '../entities/merchant_device_state.dart';
import '../repositories/device_token_repository.dart';
import '../repositories/merchant_device_repository.dart';
import '../use_cases/device_identity.dart';
import '../use_cases/device_registration_error.dart';
import '../use_cases/device_registration_status.dart';

final merchantDeviceNotifierProvider = AsyncNotifierProvider<MerchantDeviceNotifier, MerchantDeviceState>(
  MerchantDeviceNotifier.new,
  name: 'merchantDeviceNotifierProvider',
);

/// This device's enrolment with the webhook-receiver (`/devices/register`).
/// The live orders socket only connects once the enrolment is `approved` —
/// see `OrdersFeedNotifier`.
class MerchantDeviceNotifier extends AsyncNotifier<MerchantDeviceState> {
  MerchantDeviceRepository get _repository => ref.read(merchantDeviceRepositoryProvider);

  @override
  Future<MerchantDeviceState> build() async {
    final deviceId = await _repository.currentDeviceId();
    final registeredStoreId = await _repository.registeredStoreId();
    final persistedStatus = await _repository.lastKnownStatus();
    final persistedMerchantName = await _repository.lastKnownMerchantName();
    return MerchantDeviceState(
      deviceId: deviceId,
      registeredStoreId: registeredStoreId,
      persistedStatus: persistedStatus,
      persistedMerchantName: persistedMerchantName,
    );
  }

  /// Registers this device against [storeId] (the Kiosk ID). A registration
  /// is scoped to one merchant, so an existing one for a different Kiosk ID
  /// is forgotten first. Best-effort: failures land in the state's `error`.
  Future<void> registerIfNeeded({required String storeId, required String name}) async {
    try {
      final loaded = await future;
      if (loaded.isRegistering) return;

      final trimmedStoreId = storeId.trim();
      if (trimmedStoreId.isEmpty) return;
      if (loaded.isRegistered && loaded.registeredStoreId != trimmedStoreId) {
        await _repository.forget();
        state = const AsyncData(MerchantDeviceState());
      }

      final request = await ref.read(deviceIdentityProvider).describe(name: name);
      await register(request, storeId: trimmedStoreId);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] registerIfNeeded skipped: $error\n$stackTrace');
    }
  }

  /// Returns the registration on success, or the reason it failed.
  Future<({DeviceRegistrationDto? registration, DeviceRegistrationError? error})> register(
    RegisterDeviceRequest request, {
    required String storeId,
  }) async {
    final current = state.value ?? const MerchantDeviceState();
    // Guard against a double-submit while a request is already in flight.
    if (current.isRegistering) {
      return (registration: null, error: DeviceRegistrationError.rateLimited);
    }
    state = AsyncData(
      MerchantDeviceState(
        deviceId: current.deviceId,
        registeredStoreId: current.registeredStoreId,
        registration: current.registration,
        persistedStatus: current.persistedStatus,
        persistedMerchantName: current.persistedMerchantName,
        isRegistering: true,
      ),
    );

    try {
      final registration = await _repository.registerDevice(request, storeId: storeId);
      final merchantName = registration.merchantName?.trim();
      state = AsyncData(
        MerchantDeviceState(
          deviceId: registration.deviceId,
          registeredStoreId: storeId,
          registration: registration,
          persistedStatus: registration.status,
          persistedMerchantName:
              merchantName != null && merchantName.isNotEmpty ? merchantName : current.persistedMerchantName,
        ),
      );
      // The device secret / id are now in secure storage — warm the
      // `/devices/token` cache so the live-orders socket can authenticate
      // without waiting on a first mint. Best-effort: a pending-approval
      // rejection here is normal and the pre-connect step re-mints anyway.
      await _mintDeviceToken(storeId);
      if (merchantName != null &&
          merchantName.isNotEmpty &&
          deviceRegistrationStatusFrom(registration.status) == DeviceRegistrationStatus.approved) {
        await _syncLegalName(merchantName);
      }
      return (registration: registration, error: null);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] register failed: $error\n$stackTrace');
      final reason = deviceRegistrationErrorFrom(error);
      state = AsyncData(
        MerchantDeviceState(
          deviceId: current.deviceId,
          registeredStoreId: current.registeredStoreId,
          registration: current.registration,
          persistedStatus: current.persistedStatus,
          persistedMerchantName: current.persistedMerchantName,
          error: reason,
          errorMessage: deviceRegistrationMessageFrom(error, reason),
        ),
      );
      return (registration: null, error: reason);
    }
  }

  /// Runs `POST /devices/register` against the terminal's *current* Kiosk ID
  /// to pull the current approval status. Idempotent: the Idempotency-Key is
  /// the stable install id, so the backend replays the current record rather
  /// than creating a new enrollment.
  ///
  /// The Kiosk ID comes from the terminal, not the stored registration, so a
  /// Kiosk ID this device never registered against (restored from a backup,
  /// seeded, or saved while registration was skipped or failed) still gets
  /// registered here. A stored registration for a different Kiosk ID is
  /// forgotten first. Falls back to the stored Kiosk ID when the terminal
  /// can't be read.
  Future<void> refreshStatus() async {
    final MerchantDeviceState loaded;
    try {
      loaded = await future;
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] refreshStatus skipped: $error\n$stackTrace');
      return;
    }
    if (loaded.isRegistering) return;

    String? terminalKioskId;
    String? terminalLegalName;
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      terminalKioskId = terminal.kioskId.trim();
      terminalLegalName = terminal.legalName?.trim();
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] refreshStatus could not read terminal: $error\n$stackTrace');
    }

    final storeId = (terminalKioskId != null && terminalKioskId.isNotEmpty)
        ? terminalKioskId
        : loaded.registeredStoreId?.trim() ?? '';
    if (storeId.isEmpty) return;

    try {
      if (loaded.isRegistered && loaded.registeredStoreId != storeId) {
        await _repository.forget();
        state = const AsyncData(MerchantDeviceState());
      }
      final merchantName = loaded.registeredStoreId == storeId ? loaded.merchantName?.trim() : null;
      final name = [merchantName, terminalLegalName].firstWhere(
        (n) => n != null && n.isNotEmpty,
        orElse: () => 'POS Kiosk',
      )!;
      final request = await ref.read(deviceIdentityProvider).describe(name: name);
      await register(request, storeId: storeId);
    } catch (error, stackTrace) {
      // Unlike a failure inside `register`, this happens before it sets its
      // own error state (e.g. `describe` reading device info) — surface it
      // the same way so the status card's listener can still show it.
      debugPrint('[MerchantDevice] refreshStatus failed: $error\n$stackTrace');
      final reason = deviceRegistrationErrorFrom(error);
      state = AsyncData(
        (state.value ?? loaded).copyWith(error: reason, errorMessage: deviceRegistrationMessageFrom(error, reason)),
      );
    }
  }

  Future<void> _mintDeviceToken(String storeId) async {
    try {
      await ref.read(deviceTokenRepositoryProvider).refreshToken(storeId);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] device-token warm-up skipped: $error\n$stackTrace');
    }
  }

  /// Once the merchant has approved this device, the terminal's legal name
  /// follows the merchant name. Best-effort: the PATCH is admin/supervisor
  /// only, so a cashier session skips it and the next admin login syncs it.
  Future<void> _syncLegalName(String merchantName) async {
    try {
      final api = ref.read(posTerminalsApiProvider);
      final terminal = await api.getMyTerminal();
      if (terminal.legalName?.trim() == merchantName) return;
      await api.updateMyTerminal(legalName: merchantName);
      ref.invalidate(posTerminalProvider);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] legal-name sync skipped: $error\n$stackTrace');
    }
  }

  Future<void> forget() async {
    await _repository.forget();
    state = const AsyncData(MerchantDeviceState());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
