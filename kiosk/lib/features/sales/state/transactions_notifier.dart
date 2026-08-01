import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/paginated_data.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, PaginatedData<Receipt>>(
  TransactionsNotifier.new,
  name: 'transactionsProvider',
);

class TransactionsNotifier extends AsyncNotifier<PaginatedData<Receipt>> {
  @override
  Future<PaginatedData<Receipt>> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getAll(page: 1, limit: 10);
  }

  Future<void> getResults({
    required int page,
    required int limit,
    String? search,
    DateTime? soDate,
    String? sort,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(receiptRepositoryProvider);
      return repository.getAll(
        page: page,
        limit: limit,
        search: search,
        soDate: soDate,
        sort: sort,
      );
    });
  }
}
