import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/state/login_state_notifier.dart';
import '../entities/replenishment_order.dart';
import '../entities/replenishment_order_status.dart';
import '../repositories/replenishment_orders_repository.dart';

final replenishmentOrdersProvider =
    AsyncNotifierProvider<ReplenishmentOrdersNotifier, List<ReplenishmentOrder>>(
  ReplenishmentOrdersNotifier.new,
  name: 'replenishmentOrdersProvider',
);

class ReplenishmentOrdersNotifier extends AsyncNotifier<List<ReplenishmentOrder>> {
  @override
  Future<List<ReplenishmentOrder>> build() async {
    final currentUser = await ref.watch(loginStateProvider.future);
    if (currentUser == null) return [];
    return ref.watch(replenishmentOrdersRepositoryProvider).getOrders(
          customerId: currentUser.id.toString(),
        );
  }

  Future<void> refresh() async {
    final currentUser = ref.read(loginStateProvider).value;
    if (currentUser == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(replenishmentOrdersRepositoryProvider).getOrders(
            customerId: currentUser.id.toString(),
          ),
    );
  }
}

final replenishmentPendingOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(replenishmentOrdersProvider).value;
  if (orders == null) return 0;
  return orders.where((order) => order.status == ReplenishmentOrderStatus.pending).length;
});
