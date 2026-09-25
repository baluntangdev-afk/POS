import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../orders/repositories/webhook_auth_repository.dart';
import '../../orders/state/merchant_device_notifier.dart';
import '../../orders/state/webhook_auth_status_provider.dart';
import '../../orders/use_cases/webhook_auth_error.dart';

class VerifiedMerchantLockedException implements Exception {
  const VerifiedMerchantLockedException();

  String get message =>
      "This kiosk is linked to a verified merchant and can't be "
      'reassigned to a different Kiosk ID. Use Backup & Transfer instead.';

  @override
  String toString() => 'VerifiedMerchantLockedException()';
}

final savePosTerminalProvider = Provider<SavePosTerminal>(SavePosTerminal.new);

/// Saves the POS terminal details. The Kiosk ID is this device's merchant
/// (store) id on the orders service, so changing it follows the mobile app's
/// Store ID flow:
///
///  1. Moving away from a *verified* merchant is refused with
///     [VerifiedMerchantLockedException] unless the caller already confirmed
///     it ([bypassVerifiedLock]).
///  2. The new Kiosk ID is verified with `POST /auth/token` before anything is
///     saved — a rejected (unknown) merchant leaves the terminal untouched.
///  3. After saving, this device is registered against the new Kiosk ID in
///     the background (`POST /devices/register`).
///
/// Each sale is stamped with the Kiosk ID it was made under, so switching
/// here doesn't touch pre-existing sales or their sync eligibility — that's
/// what the separate "Transfer" prompt is for.
class SavePosTerminal {
  const SavePosTerminal(this._ref);

  final Ref _ref;

  Future<void> call({
    required String previousKioskId,
    required String kioskId,
    required String legalName,
    required String address,
    required String tinNumber,
    bool bypassVerifiedLock = false,
  }) async {
    final previous = previousKioskId.trim();
    final next = kioskId.trim();
    final kioskIdChanged = next != previous;

    if (kioskIdChanged && previous.isNotEmpty && !bypassVerifiedLock && await _isVerified(previous)) {
      throw const VerifiedMerchantLockedException();
    }

    // With device registration skipped there's no merchant to verify
    // against, so the Kiosk ID is saved as-is.
    String? merchantName;
    if (kioskIdChanged && next.isNotEmpty && !kSkipDeviceRegistration) {
      merchantName = (await _refreshToken(next))?.trim();
    }

    await _ref
        .read(posTerminalsApiProvider)
        .updateMyTerminal(kioskId: next, legalName: legalName, address: address, tinNumber: tinNumber);

    if (kioskIdChanged) {
      unawaited(
        _registerDevice(
          storeId: next,
          deviceName: merchantName != null && merchantName.isNotEmpty ? merchantName : legalName.trim(),
        ),
      );
    }
  }

  /// Registers this device against [storeId]. Only called once `/auth/token`
  /// has already confirmed the merchant exists, so a rejected ID never
  /// reaches this step. The outcome surfaces through
  /// `merchantDeviceNotifierProvider` (see `handleMerchantDeviceOutcome`).
  Future<void> _registerDevice({required String storeId, required String deviceName}) async {
    if (kSkipDeviceRegistration || storeId.isEmpty) return;
    try {
      await _ref.read(merchantDeviceNotifierProvider.notifier).registerIfNeeded(storeId: storeId, name: deviceName);
    } catch (error, stackTrace) {
      debugPrint('[SavePosTerminal] device registration failed for $storeId: $error\n$stackTrace');
    }
  }

  Future<bool> _isVerified(String storeId) async {
    try {
      await _ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
      return true;
    } on WebhookAuthException {
      return false;
    }
  }

  Future<String?> _refreshToken(String storeId) async {
    final status = _ref.read(webhookAuthStatusProvider.notifier);
    try {
      final merchantName = await _ref.read(webhookAuthRepositoryProvider).refreshToken(storeId);
      status.clear();
      return merchantName;
    } on WebhookAuthException catch (error) {
      status.reportFailure(error.reason, error.message);
      rethrow;
    }
  }
}
