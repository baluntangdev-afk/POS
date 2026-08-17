import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/cartivo_product.dart';
import '../repositories/cartivo_products_repository.dart';

final cartivoProductsProvider =
    AsyncNotifierProvider<CartivoProductsNotifier, List<CartivoProduct>>(
  CartivoProductsNotifier.new,
  name: 'cartivoProductsProvider',
);

class CartivoProductsNotifier extends AsyncNotifier<List<CartivoProduct>> {
  @override
  Future<List<CartivoProduct>> build() {
    return ref.watch(cartivoProductsRepositoryProvider).getProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cartivoProductsRepositoryProvider).getProducts(),
    );
  }
}
