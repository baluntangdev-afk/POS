import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/replenishment_cart_item.dart';
import '../entities/replenishment_product.dart';

final replenishmentCartProvider =
    NotifierProvider<ReplenishmentCartNotifier, IList<ReplenishmentCartItem>>(
  ReplenishmentCartNotifier.new,
  name: 'replenishmentCartProvider',
);

class ReplenishmentCartNotifier extends Notifier<IList<ReplenishmentCartItem>> {
  @override
  IList<ReplenishmentCartItem> build() => const IList.empty();

  void addItem(ReplenishmentProduct product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = state.add(ReplenishmentCartItem(product: product, quantity: 1));
      return;
    }
    final item = state[index];
    state = state.replace(index, item.copyWith(quantity: item.quantity + 1));
  }

  void incrementItem(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    final item = state[index];
    state = state.replace(index, item.copyWith(quantity: item.quantity + 1));
  }

  void decrementItem(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    final item = state[index];
    if (item.quantity <= 1) {
      state = state.removeAt(index);
      return;
    }
    state = state.replace(index, item.copyWith(quantity: item.quantity - 1));
  }

  void removeItem(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    state = state.removeAt(index);
  }

  void clear() {
    state = const IList.empty();
  }
}
