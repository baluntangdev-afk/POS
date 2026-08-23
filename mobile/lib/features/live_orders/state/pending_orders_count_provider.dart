import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../settings/state/store_info_notifier.dart';
import '../entities/order_event.dart';
import '../repositories/order_events_local_repository.dart';

/// Count of this store's orders that aren't cancelled, per the locally
/// persisted (on-disk) latest event for each order. Survives app restarts
/// and reflects orders received while the live feed was disconnected — not
/// just what's in the in-memory feed state. Backs the badge on the Orders
/// tile and the status pill on the Dashboard.
final pendingOrdersCountProvider = StreamProvider<int>((ref) async* {
  final storeInfo = await ref.watch(storeInfoProvider.future);
  final storeId = storeInfo?.storeId ?? '';
  if (storeId.isEmpty) {
    yield 0;
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchPendingCount(storeId);
});

/// The persisted orders themselves, most recently updated first — same
/// underlying source as [pendingOrdersCountProvider], so the Orders screen
/// list always matches what the badge counts.
final persistedOrdersProvider = StreamProvider<List<OrderEvent>>((ref) async* {
  final storeInfo = await ref.watch(storeInfoProvider.future);
  final storeId = storeInfo?.storeId ?? '';
  if (storeId.isEmpty) {
    yield const [];
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchOrders(storeId);
});
