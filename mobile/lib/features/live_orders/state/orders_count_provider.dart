import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../settings/state/store_info_notifier.dart';
import '../entities/order_event.dart';
import '../repositories/order_events_local_repository.dart';

/// The current store's ID for the on-disk order queries, or `''` when there is
/// no store yet **or** the last store-info save failed to provision.
///
/// An unrecognized merchant/store ID leaves [storeInfoProvider] in an error
/// state whose retained value is still the *previous* store, and any provider
/// that let that error propagate would keep serving its own last good value.
/// Swallowing it here means the Dashboard badge clears to 0 and the Orders list
/// empties instead of both freezing at the previous merchant's data. The user
/// is told what actually went wrong by the auth-failure toast (`main.dart`) and
/// the Orders screen's error state — both driven by `webhookAuthStatusProvider`.
Future<String> _activeStoreId(Ref ref) async {
  try {
    final storeInfo = await ref.watch(storeInfoProvider.future);
    return storeInfo?.storeId ?? '';
  } catch (_) {
    return '';
  }
}

/// Count of this store's orders, per the locally persisted (on-disk) latest
/// event for each order — every order on record, with no status filtering, so
/// it equals the length of the Orders list and the number of distinct orders
/// the history endpoint returned. Survives app restarts and reflects orders
/// received while the live feed was disconnected. Backs the badge on the
/// Orders tile and the status pill on the Dashboard.
final ordersCountProvider = StreamProvider<int>((ref) async* {
  final storeId = await _activeStoreId(ref);
  if (storeId.isEmpty) {
    yield 0;
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchOrderCount(storeId);
});

/// The persisted orders themselves, most recently updated first — same
/// underlying source as [ordersCountProvider], so the Orders screen
/// list always matches what the badge counts.
final persistedOrdersProvider = StreamProvider<List<OrderEvent>>((ref) async* {
  final storeId = await _activeStoreId(ref);
  if (storeId.isEmpty) {
    yield const [];
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchOrders(storeId);
});
