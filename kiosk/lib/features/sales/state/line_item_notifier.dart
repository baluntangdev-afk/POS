import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/product.dart';
import '../repositories/product_repository.dart';

final lineItemProvider = AsyncNotifierProvider.autoDispose.family(
  LineItemNotifier.new,
  name: 'lineItemProvider',
);

class LineItemNotifier extends AsyncNotifier<Product> {
  LineItemNotifier(this.id);

  final int id;

  @override
  Future<Product> build() async {
    final repository = ref.watch(productRepositoryProvider);
    return repository.getById(id);
  }
}
