import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cartivo_cart_item.dart';
import '../entities/cartivo_product.dart';

final cartivoCartProvider = NotifierProvider<CartivoCartNotifier, IList<CartivoCartItem>>(
  CartivoCartNotifier.new,
  name: 'cartivoCartProvider',
);

class CartivoCartNotifier extends Notifier<IList<CartivoCartItem>> {
  @override
  IList<CartivoCartItem> build() => const IList.empty();

  void addItem(CartivoProduct product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = state.add(CartivoCartItem(product: product, quantity: 1));
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
