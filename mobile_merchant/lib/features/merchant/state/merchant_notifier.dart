import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../domain/entities/merchant.dart';
import '../domain/repositories/merchant_repository.dart';

class MerchantNotifier extends AsyncNotifier<Merchant?> {
  @override
  Future<Merchant?> build() => getIt<MerchantRepository>().getMerchant();

  Future<void> register({
    required String merchantId,
    required String merchantName,
  }) async {
    final repo = getIt<MerchantRepository>();
    await repo.createMerchant(merchantId: merchantId, merchantName: merchantName);
    await repo.activateDevice(merchantId);
    state = await AsyncValue.guard(build);
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

    if (existing.merchantId != merchantId) {
      await repo.clearDeviceCredentials();
      await repo.activateDevice(merchantId);
    }

    state = await AsyncValue.guard(build);
  }
}

final merchantProvider =
    AsyncNotifierProvider<MerchantNotifier, Merchant?>(MerchantNotifier.new);
