import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/replenishment_order.dart';
import '../entities/replenishment_payment.dart';
import '../repositories/replenishment_orders_repository.dart';
import 'replenishment_orders_notifier.dart';

typedef ReplenishmentPayOrderResult = ({ReplenishmentOrder order, ReplenishmentPayment payment});

final replenishmentPayOrderProvider = AsyncNotifierProvider.autoDispose.family<
    ReplenishmentPayOrderNotifier, ReplenishmentPayOrderResult?, String>(
  ReplenishmentPayOrderNotifier.new,
  name: 'replenishmentPayOrderProvider',
);

class ReplenishmentPayOrderNotifier extends AsyncNotifier<ReplenishmentPayOrderResult?> {
  ReplenishmentPayOrderNotifier(this.orderId);

  final String orderId;

  @override
  Future<ReplenishmentPayOrderResult?> build() async => null;

  Future<void> pay() async {
    state = const AsyncLoading<ReplenishmentPayOrderResult?>();
    state = await AsyncValue.guard<ReplenishmentPayOrderResult?>(
      () => ref.read(replenishmentOrdersRepositoryProvider).payOrder(orderId),
    );
    if (state.hasValue) {
      ref.invalidate(replenishmentOrdersProvider);
    }
  }
}
