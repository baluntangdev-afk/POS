import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/merchant_device_storage.dart';
import '../domain/entities/device_registration.dart';
import '../domain/entities/device_startup_result.dart';
import '../domain/entities/merchant.dart';
import '../domain/repositories/merchant_repository.dart';

class MerchantNotifier extends AsyncNotifier<Merchant?> {
  @override
  Future<Merchant?> build() => getIt<MerchantRepository>().getMerchant();

  Future<DeviceRegistration> register({
    required String merchantId,
    required String merchantName,
  }) async {
    final repo = getIt<MerchantRepository>();
    await repo.createMerchant(merchantId: merchantId, merchantName: merchantName);
    final registration = await repo.activateDevice(merchantId);
    state = await AsyncValue.guard(build);
    return registration;
  }

  Future<DeviceStartupResult> syncOnStartup() async {
    final merchant = state.value;
    if (merchant == null) return const DeviceStartupResult.tokenUnavailable();

    final repo = getIt<MerchantRepository>();
    final prev = await getIt<MerchantDeviceStorage>().deviceStatus;

    try {
      // Ensures a token scoped to *this* merchant — re-mints when the stored
      // one is missing, expiring, or left over from a previous merchant.
      await repo.ensureWebhookToken(merchant.merchantId);
    } catch (_) {
      return const DeviceStartupResult.tokenUnavailable();
    }

    final DeviceRegistration registration;
    try {
      registration = await repo.syncDeviceRegistration();
    } catch (_) {
      return const DeviceStartupResult.tokenUnavailable();
    }

    final next = registration.status;
    final justApproved = prev != null &&
        prev != DeviceStatus.approved &&
        next == DeviceStatus.approved;

    // Re-emit `merchantProvider` only when the record actually changed. A blind
    // reassignment on every launch pushes a fresh `Future` onto
    // `merchantProvider.future`, which notifies its watchers unconditionally
    // (no equality gate) — that makes `OrdersNotifier` rebuild and flash the
    // dashboard's loading spinner a second time.
    final refreshed = await AsyncValue.guard(build);
    if (refreshed != AsyncData<Merchant?>(state.value)) {
      state = refreshed;
    }

    final approved = next == DeviceStatus.approved;
    return DeviceStartupResult(
      status: next,
      justApproved: justApproved,
      reviewNote: registration.reviewNote,
      deviceId: approved ? registration.deviceId : null,
      deviceSecret: approved ? registration.deviceSecret : null,
    );
  }

  /// Re-runs the once-per-launch device-approval probe on demand, outside the
  /// [deviceStartupProvider] memoization that otherwise pins the result to
  /// whatever the app saw at cold start.
  ///
  /// Refreshing the provider re-emits to everything watching it — most
  /// importantly `OrdersFeedNotifier.build()`, which reconnects the live feed
  /// on its own once the status flips to `approved`. Safe to call repeatedly:
  /// `POST /devices/register` is idempotent and [MerchantNotifier.syncOnStartup]
  /// only reports `justApproved` on the actual transition.
  Future<DeviceStartupResult> recheckDeviceStatus() {
    return ref.refresh(deviceStartupProvider.future);
  }

  Future<void> refreshToken() async {
    final merchant = state.value;
    if (merchant == null) return;
    await getIt<MerchantRepository>().refreshToken(merchant.merchantId);
    state = await AsyncValue.guard(build);
  }

  Future<void> save({
    required String merchantId,
    required String merchantName,
  }) async {
    final repo = getIt<MerchantRepository>();
    final existing = state.value;
    if (existing == null) return;

    await repo.updateMerchant(
      id: existing.id,
      merchantId: merchantId,
      merchantName: merchantName,
    );

    final merchantChanged = existing.merchantId != merchantId;
    if (merchantChanged) {
      await repo.clearDeviceCredentials();
      await repo.activateDevice(merchantId);
    }

    // Publish the new merchant BEFORE invalidating deviceStartupProvider.
    // syncOnStartup() reads the merchant off this notifier's state and calls
    // refreshToken(merchant.merchantId) — if it recomputes while state is still
    // the old merchant, it overwrites the freshly minted token with one scoped
    // to the previous merchant, and every subsequent request 403s.
    state = await AsyncValue.guard(build);

    // Re-run the device-approval probe on every settings save, not just a
    // merchant change — mirrors `mobile/`, where saving store info re-provisions
    // the device. The probe is idempotent (`Idempotency-Key: installId`), so a
    // no-op save just replays the current enrollment record.
    ref.invalidate(deviceStartupProvider);
  }
}

final merchantProvider =
    AsyncNotifierProvider<MerchantNotifier, Merchant?>(MerchantNotifier.new);

/// Runs the once-per-launch device auth chain (`POST /auth/token` →
/// `POST /devices/register`) exactly once and memoizes the result. Awaited by
/// both the dashboard and `OrdersFeedNotifier.build()`, so the live feed can
/// never mint `/devices/token` before registration has resolved.
final deviceStartupProvider = FutureProvider<DeviceStartupResult>((ref) async {
  // ref.read, not watch: syncOnStartup() reassigns merchantProvider's state,
  // and watching it here would retrigger this provider (and the whole chain).
  // MerchantNotifier.save() invalidates this provider explicitly when the
  // merchant changes.
  final merchant = await ref.read(merchantProvider.future);
  if (merchant == null) return const DeviceStartupResult.tokenUnavailable();
  return ref.read(merchantProvider.notifier).syncOnStartup();
});
