import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../live_orders/repositories/webhook_auth_repository.dart';
import '../../live_orders/use_cases/webhook_auth_error.dart';
import 'store_info_notifier.dart';

/// Whether the current store/merchant id is recognized by the orders
/// service — i.e. `POST /auth/token` succeeds for it. Gates the
/// device-approval widget on the Store Information screen: an unrecognized
/// merchant shouldn't be offered device registration.
final merchantVerificationProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final storeInfo = await ref.watch(storeInfoProvider.future);
  final storeId = storeInfo?.storeId.trim() ?? '';
  if (storeId.isEmpty) return false;

  try {
    await ref.read(webhookAuthRepositoryProvider).ensureToken(storeId);
    return true;
  } on WebhookAuthException catch (error) {
    debugPrint('[MerchantVerification] $storeId not verified: $error');
    return false;
  }
});
