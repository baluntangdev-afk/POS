import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cartivo_order.dart';
import '../entities/cartivo_order_status.dart';
import '../repositories/cartivo_orders_repository.dart';

final cartivoOrdersProvider = AsyncNotifierProvider<CartivoOrdersNotifier, List<CartivoOrder>>(
  CartivoOrdersNotifier.new,
  name: 'cartivoOrdersProvider',
);

class CartivoOrdersNotifier extends AsyncNotifier<List<CartivoOrder>> {
  @override
  Future<List<CartivoOrder>> build() {
    return ref.watch(cartivoOrdersRepositoryProvider).getOrders();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cartivoOrdersRepositoryProvider).getOrders());
  }
}

final cartivoPendingOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(cartivoOrdersProvider).value;
  if (orders == null) return 0;
  return orders.where((order) => order.status == CartivoOrderStatus.pending).length;
});
