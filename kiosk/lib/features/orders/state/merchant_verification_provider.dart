import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../menu/state/pos_terminal_notifier.dart';
import '../repositories/webhook_auth_repository.dart';
import '../use_cases/webhook_auth_error.dart';

/// Whether the current Kiosk ID is recognized by the orders service as a
/// merchant — i.e. `POST /auth/token` succeeds for it. An unverified Kiosk ID
/// is an "unregistered merchant": it isn't offered device registration, and
/// its local sales can be transferred to the next verified Kiosk ID.
final merchantVerificationProvider = FutureProvider.autoDispose<bool>((ref) async {
  final terminal = await ref.watch(posTerminalProvider.future);
  final storeId = terminal.kioskId.trim();
  if (storeId.isEmpty) return false;

  try {
    await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
    return true;
  } on WebhookAuthException catch (error) {
    debugPrint('[MerchantVerification] $storeId not verified: $error');
    return false;
  }
});
