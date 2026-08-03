import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/transaction_summary.dart';

class TransactionsPage {
  final List<TransactionSummary> items;
  final int totalCount;
  final int offset;
  final int limit;

  const TransactionsPage({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + items.length < totalCount;
}

class TransactionsNotifier extends AsyncNotifier<TransactionsPage> {
  DateTime? _date;
  String? _search;
  bool _loadingMore = false;
  static const _pageSize = 20;

  DateTime? get date => _date;
  String? get search => _search;

  @override
  Future<TransactionsPage> build() => _load();

  Future<TransactionsPage> _load({int offset = 0}) async {
    final db = ref.watch(databaseProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final cashierId = (user == null || user.isAdminOrSupervisor) ? null : user.id;
    final items = await db.salesDao.getTransactions(
      date: _date,
      search: _search,
      cashierId: cashierId,
      limit: _pageSize,
      offset: offset,
    );
    final totalCount = await db.salesDao.getTransactionCount(
      date: _date,
      search: _search,
      cashierId: cashierId,
    );
    return TransactionsPage(items: items, totalCount: totalCount, offset: offset, limit: _pageSize);
  }

  Future<void> setDate(DateTime? date) async {
    _date = date;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> setSearch(String? query) async {
    _search = (query?.trim().isEmpty ?? true) ? null : query!.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (_loadingMore || current == null || !current.hasMore) return;
    _loadingMore = true;
    try {
      final result = await AsyncValue.guard(
        () => _load(offset: current.offset + current.items.length),
      );
      state = result.when(
        data: (next) => AsyncValue.data(TransactionsPage(
          items: [...current.items, ...next.items],
          totalCount: next.totalCount,
          offset: next.offset,
          limit: next.limit,
        )),
        error: (e, st) => AsyncValue.error(e, st),
        loading: () => state,
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, TransactionsPage>(TransactionsNotifier.new);
