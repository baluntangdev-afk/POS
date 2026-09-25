import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../data/backend_api/enums/payment_method.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../orders/repositories/webhook_auth_repository.dart';
import '../../orders/state/merchant_device_notifier.dart';
import '../../orders/state/webhook_auth_status_provider.dart';
import '../../orders/use_cases/webhook_auth_error.dart';

typedef PendingPaymentMethod = ({PaymentMethod method, String? methodName, String? number});

final registerPosTerminalProvider = Provider<RegisterPosTerminal>(RegisterPosTerminal.new);

/// First-run creation of this device's POS terminal, including its Kiosk ID.
/// Follows the same order as [SavePosTerminal] when a Kiosk ID changes:
///
///  1. The Kiosk ID is verified with `POST /auth/token` — an unknown merchant
///     throws [WebhookAuthException] and nothing is created.
///  2. The terminal is created with that Kiosk ID, then the pending payment
///     methods are added.
///  3. This device is registered against the Kiosk ID in the background
///     (`POST /devices/register`).
class RegisterPosTerminal {
  const RegisterPosTerminal(this._ref);

  final Ref _ref;

  Future<void> call({
    required String kioskId,
    required String legalName,
    required String address,
    required String tinNumber,
    List<PendingPaymentMethod> paymentMethods = const [],
  }) async {
    final id = kioskId.trim();

    // With device registration skipped there's no merchant to verify
    // against, so the Kiosk ID is saved as-is.
    String? merchantName;
    if (!kSkipDeviceRegistration) {
      merchantName = (await _refreshToken(id))?.trim();
    }

    final api = _ref.read(posTerminalsApiProvider);
    await api.registerMyTerminal(
      kioskId: id,
      legalName: legalName.trim(),
      address: address.trim(),
      tinNumber: tinNumber.trim(),
    );
    for (final pm in paymentMethods) {
      await api.addPaymentMethod(
        paymentMethod: pm.method,
        paymentMethodName: pm.methodName,
        paymentNumber: pm.number,
      );
    }

    unawaited(
      _registerDevice(
        storeId: id,
        deviceName: merchantName != null && merchantName.isNotEmpty ? merchantName : legalName.trim(),
      ),
    );
  }

  /// The outcome surfaces through `merchantDeviceNotifierProvider` (see
  /// `handleMerchantDeviceOutcome`).
  Future<void> _registerDevice({required String storeId, required String deviceName}) async {
    if (kSkipDeviceRegistration || storeId.isEmpty) return;
    try {
      await _ref.read(merchantDeviceNotifierProvider.notifier).registerIfNeeded(storeId: storeId, name: deviceName);
    } catch (error, stackTrace) {
      debugPrint('[RegisterPosTerminal] device registration failed for $storeId: $error\n$stackTrace');
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
