import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../entities/order_event.dart';
import '../repositories/order_events_local_repository.dart';
import 'orders_feed_notifier.dart';

/// Resolves the current kiosk id independently of the live-feed socket, so
/// the pending-orders badge reflects what's durably stored even before (or
/// without) a live connection — e.g. right after app launch, or while
/// [OrdersFeedNotifier] is offline/reconnecting. Prefers the feed's kioskId
/// once known (no extra request); falls back to a direct terminal lookup.
final resolvedKioskIdProvider = FutureProvider<String?>((ref) async {
  final feedKioskId = ref.watch(ordersFeedNotifierProvider.select((s) => s.value?.kioskId));
  if (feedKioskId != null) return feedKioskId;

  try {
    final terminal = await ref.watch(posTerminalsApiProvider).getMyTerminal();
    return terminal.kioskId;
  } catch (_) {
    return null;
  }
});

/// Count of this kiosk's orders that aren't cancelled, per the locally
/// persisted (on-disk) latest event for each order. Survives app restarts
/// and reflects orders received while the live feed was disconnected — not
/// just what's in the in-memory feed state. Backs the always-visible badge
/// on the Orders menu tile.
final pendingOrdersCountProvider = StreamProvider<int>((ref) async* {
  final kioskId = await ref.watch(resolvedKioskIdProvider.future);
  if (kioskId == null) {
    yield 0;
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchPendingCount(kioskId);
});

/// The persisted orders themselves, most recently updated first — same
/// underlying source as [pendingOrdersCountProvider], so the Orders screen
/// list always matches what the badge counts.
final persistedOrdersProvider = StreamProvider<List<OrderEvent>>((ref) async* {
  final kioskId = await ref.watch(resolvedKioskIdProvider.future);
  if (kioskId == null) {
    yield const [];
    return;
  }

  final repository = ref.watch(orderEventsLocalRepositoryProvider);
  yield* repository.watchOrders(kioskId);
});

/// Deletes every persisted order for the current kiosk. Used by the
/// Orders screen's "delete all" action; the list/badge update on their own
/// once the underlying rows are gone, since both stream from the same DAO.
Future<void> deleteAllOrders(WidgetRef ref) async {
  final kioskId = await ref.read(resolvedKioskIdProvider.future);
  if (kioskId == null) return;
  await ref.read(orderEventsLocalRepositoryProvider).deleteAll(kioskId);
}
