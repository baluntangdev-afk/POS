import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/transaction_sync/sales_sync_signal.dart';
import '../../../exceptions/exception_extension.dart';
import '../../../widgets/message_dialog.dart';
import '../../orders/state/merchant_verification_provider.dart';
import '../../orders/use_cases/webhook_auth_error.dart';
import '../../transaction_sync/repositories/transaction_sync_repository.dart';
import '../use_cases/save_pos_terminal.dart';

/// User-facing text for a failed POS terminal save.
String posTerminalSaveErrorMessage(Object error) => switch (error) {
  WebhookAuthException(:final message) => message,
  VerifiedMerchantLockedException(:final message) => message,
  _ => error.message,
};

/// Whether changing the Kiosk ID should offer to transfer this device's
/// existing sales to the new merchant: only when the previous Kiosk ID was
/// never a verified merchant (an unregistered merchant) and there's local
/// history to move.
Future<bool> shouldOfferDataTransfer(WidgetRef ref, {required String previousKioskId, required String newKioskId}) async {
  if (previousKioskId.trim() == newKioskId.trim()) return false;
  final previouslyVerified = ref.read(merchantVerificationProvider).value ?? false;
  if (previouslyVerified) return false;
  return ref.read(transactionSyncRepositoryProvider).hasAnyTransactions();
}

/// Shown when the user tries to change the Kiosk ID away from a merchant the
/// orders service already recognizes as verified. Proceeding still verifies
/// and registers the device against the new Kiosk ID as usual, but sales still
/// pending sync under the old merchant stay stamped with it, so they aren't
/// pushed under the new one.
Future<bool> confirmReassignVerifiedKioskId(BuildContext context) async {
  var proceed = false;
  await showMessageDialog(
    context,
    type: DialogType.warning,
    title: 'Verified Merchant',
    message:
        '${const VerifiedMerchantLockedException().message} '
        'Proceeding will reassign this kiosk to the new Kiosk ID; any sales '
        'data still pending sync will not be sent to it.',
    primaryButtonText: 'Proceed',
    secondaryButtonText: 'Cancel',
    barrierDismissible: false,
    onPrimaryPressed: () {
      proceed = true;
      Navigator.of(context, rootNavigator: true).pop();
    },
    onSecondaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
  );
  return proceed;
}

/// Offers to move every existing sale/refund to [newKioskId] — the now-active,
/// verified merchant — on the next sync.
Future<void> maybeOfferDataTransfer(BuildContext context, WidgetRef ref, {required String newKioskId}) {
  return showMessageDialog(
    context,
    type: DialogType.info,
    title: 'Existing Data Found',
    message:
        'This kiosk has existing sales data. It will be transferred to the '
        'now-active merchant on the next sync.',
    primaryButtonText: 'Transfer',
    secondaryButtonText: 'Not Now',
    barrierDismissible: false,
    onPrimaryPressed: () async {
      final navigator = Navigator.of(context, rootNavigator: true);
      try {
        await ref.read(transactionSyncRepositoryProvider).transferAll(newKioskId);
        ref.read(salesSyncSignalProvider).notify();
      } catch (error) {
        navigator.pop();
        if (context.mounted) {
          await showMessageDialog(
            context,
            type: DialogType.error,
            title: 'Transfer Failed',
            message: error.message,
          );
        }
        return;
      }
      navigator.pop();
    },
    onSecondaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
  );
}
