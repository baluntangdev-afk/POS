import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/replenishment_product.dart';
import '../repositories/replenishment_repository.dart';

final replenishmentProductsProvider =
    AsyncNotifierProvider<ReplenishmentProductsNotifier, List<ReplenishmentProduct>>(
  ReplenishmentProductsNotifier.new,
  name: 'replenishmentProductsProvider',
);

class ReplenishmentProductsNotifier extends AsyncNotifier<List<ReplenishmentProduct>> {
  @override
  Future<List<ReplenishmentProduct>> build() {
    return ref.watch(replenishmentRepositoryProvider).getProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(replenishmentRepositoryProvider).getProducts(),
    );
  }
}
