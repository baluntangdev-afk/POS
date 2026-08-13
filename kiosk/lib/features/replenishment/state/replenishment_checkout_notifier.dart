import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/state/login_state_notifier.dart';
import '../entities/replenishment_order.dart';
import '../repositories/replenishment_orders_repository.dart';
import 'replenishment_cart_notifier.dart';
import 'replenishment_orders_notifier.dart';

final replenishmentCheckoutProvider =
    AsyncNotifierProvider.autoDispose<ReplenishmentCheckoutNotifier, ReplenishmentOrder?>(
  ReplenishmentCheckoutNotifier.new,
  name: 'replenishmentCheckoutProvider',
);

class ReplenishmentCheckoutNotifier extends AsyncNotifier<ReplenishmentOrder?> {
  @override
  Future<ReplenishmentOrder?> build() async => null;

  Future<void> checkout() async {
    final currentUser = ref.read(loginStateProvider).value;
    if (currentUser == null) {
      state = AsyncError<ReplenishmentOrder?>(
        StateError('No logged-in user found. Please sign in again.'),
        StackTrace.current,
      );
      return;
    }

    final cartItems = ref.read(replenishmentCartProvider);
    if (cartItems.isEmpty) return;

    state = const AsyncLoading<ReplenishmentOrder?>();
    state = await AsyncValue.guard(() async {
      final order = await ref.read(replenishmentOrdersRepositoryProvider).createOrder(
            customerId: currentUser.id.toString(),
            items: cartItems.toList(),
          );
      ref.read(replenishmentCartProvider.notifier).clear();
      ref.invalidate(replenishmentOrdersProvider);
      return order;
    });
  }
}
