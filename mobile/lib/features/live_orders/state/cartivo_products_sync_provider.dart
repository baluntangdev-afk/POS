import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../settings/state/store_info_notifier.dart';
import '../use_cases/sync_cartivo_products.dart';

class CartivoSyncProgressState {
  const CartivoSyncProgressState(this.fetched, this.total);

  final int fetched;
  final int total;

  double? get fraction => total > 0 ? (fetched / total).clamp(0.0, 1.0) : null;
}

/// Live page-by-page progress of the running sync, or null when none is running.
class CartivoProductsSyncNotifier extends Notifier<CartivoSyncProgressState?> {
  @override
  CartivoSyncProgressState? build() => null;

  Future<void> sync(String merchantId) async {
    if (state != null) return;
    state = const CartivoSyncProgressState(0, 0);
    try {
      await ref.read(syncCartivoProductsProvider)(
        merchantId,
        onProgress: (fetched, total) {
          state = CartivoSyncProgressState(fetched, total);
        },
      );
    } finally {
      state = null;
    }
  }

  Future<void> retry() async {
    final merchantId =
        (await ref.read(storeInfoProvider.future))?.storeId ?? '';
    if (merchantId.isEmpty) return;
    await sync(merchantId);
  }
}

final cartivoProductsSyncProvider =
    NotifierProvider<CartivoProductsSyncNotifier, CartivoSyncProgressState?>(
      CartivoProductsSyncNotifier.new,
    );

/// Persisted sync status (idle / syncing / failed) for the current store.
final cartivoSyncStateProvider = StreamProvider<CartivoSyncStateTableData?>((
  ref,
) async* {
  final storeId = (await ref.watch(storeInfoProvider.future))?.storeId ?? '';
  if (storeId.isEmpty) {
    yield null;
    return;
  }
  yield* ref.watch(databaseProvider).cartivoProductsDao.watchSyncState(storeId);
});

/// Number of Cartivo products saved locally for the current store.
final cartivoProductCountProvider = StreamProvider<int>((ref) async* {
  final storeId = (await ref.watch(storeInfoProvider.future))?.storeId ?? '';
  if (storeId.isEmpty) {
    yield 0;
    return;
  }
  yield* ref.watch(databaseProvider).cartivoProductsDao.watchProductCount(storeId);
});
