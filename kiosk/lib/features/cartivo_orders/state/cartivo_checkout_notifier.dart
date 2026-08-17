import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../cartivo_products/state/cartivo_cart_notifier.dart';
import '../entities/cartivo_order.dart';
import '../repositories/cartivo_orders_repository.dart';
import 'cartivo_orders_notifier.dart';

final cartivoCheckoutProvider =
    AsyncNotifierProvider.autoDispose<CartivoCheckoutNotifier, CartivoOrder?>(
  CartivoCheckoutNotifier.new,
  name: 'cartivoCheckoutProvider',
);

class CartivoCheckoutNotifier extends AsyncNotifier<CartivoOrder?> {
  @override
  Future<CartivoOrder?> build() async => null;

  Future<void> checkout() async {
    final cartItems = ref.read(cartivoCartProvider);
    if (cartItems.isEmpty) return;

    state = const AsyncLoading<CartivoOrder?>();
    state = await AsyncValue.guard(() async {
      final order = await ref
          .read(cartivoOrdersRepositoryProvider)
          .createOrder(items: cartItems.toList());
      ref.read(cartivoCartProvider.notifier).clear();
      ref.invalidate(cartivoOrdersProvider);
      return order;
    });
  }
}
