# Orders history backfill (REST) — mobile — design

## Problem

The kiosk already backfills its local order history from the
webhook-receiver's REST history endpoint (see
`docs/superpowers/specs/2026-08-24-orders-history-backfill-design.md`,
which explicitly scoped mobile out). The mobile app has the same gap: its
Orders screen and pending-orders badge are backed entirely by events the
live WebSocket feed (`OrdersFeedNotifier`) has received since the app last
connected. If the device was offline, freshly installed, or just switched
to a new store ID, it has no way to see orders that happened before the
socket connected.

```
GET https://<orders-live-feed-host>/webhooks/events?merchant_id=<storeId>
```

Response shape (one item per stored event):

```json
{
  "merchant_id": "merch_...",
  "events": [
    {
      "id": 40,
      "received_at": "2026-08-21T06:35:15.549Z",
      "event_id": "evt_...",
      "event_type": "order.created",
      "created_at": "2026-08-21T06:35:14.918Z",
      "data": { "...": "same shape the WS feed sends as `data`" }
    }
  ]
}
```

This is a superset of the WS message shape (`{event_type, event_id, data}`),
so the existing WS JSON parser can be reused as-is.

## Goal

Use this endpoint to backfill the mobile app's local order history:
- once after login,
- once after saving the store settings (store ID may have changed),
- on entering the Orders screen, and via pull-to-refresh on that screen,

without letting it clobber fresher state the live socket has already
written.

## Where the endpoint lives

Same host as `AppEnv.ordersLiveFeedWsUrl` (`dposocket.onrender.com`
today). Rather than deriving the http(s) URL from the ws(s) one at
runtime, it gets its own dedicated env var, `ORDERS_EVENTS_API_BASE_URL`
(added to `AppEnv`/`Env`, `.env.sample`, value
`https://dposocket.onrender.com` in the local `.env`) — matching the
kiosk's `AppEnv.ordersEventsApiBaseUrl`.

## Starting point: mobile has no REST client today

Unlike the kiosk (which uses `dio` throughout `lib/data/backend_api/`),
`mobile/` currently makes zero HTTP calls — its only network I/O is the
live-orders WebSocket via `web_socket_channel`, called directly from
`OrdersLiveFeedRepositoryImpl`. This design introduces `dio` (pinned to
`^5.9.0`, matching the kiosk) and a new `lib/data/backend_api/` folder,
mirroring the kiosk's structure so future REST needs have a home to slot
into.

## Components

### 0. Dependency

`dio: ^5.9.0` added to `mobile/pubspec.yaml`.

### 1. `ordersEventsApiClientProvider` (new, `lib/data/backend_api/api_clients.dart`)

```dart
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl));
});
```

Unauthenticated, no interceptors — this is the only REST client mobile
has, so no shared `httpClientProvider` abstraction is introduced; if a
second REST client shows up later, factor the shared bits out then.

### 2. Shared event parser (`OrderEvent.fromWireJson`, in `entities/order_event.dart`)

The JSON→`OrderEvent` parsing logic currently private to
`OrdersLiveFeedRepositoryImpl._parse` (read `event_type` via
`OrderEventType.fromWire`, `event_id`, `data` via `OrderData.fromJson`,
return `null` on an unrecognized `event_type` or parse failure, `null` on
any other parse exception) is extracted into a static factory on
`OrderEvent`. Both the WS repository and the new REST source call it, so
"what counts as a valid event" can't drift between the two paths.

### 3. `OrdersHistoryApi` (new, `lib/data/backend_api/sources/orders_history_api.dart`)

```dart
class OrdersHistoryApi {
  const OrdersHistoryApi(this._httpClient);
  final Dio _httpClient;

  Future<List<OrderEvent>> fetchEvents(String merchantId) async {
    final response = await _httpClient.get<dynamic>(
      '/webhooks/events',
      queryParameters: {'merchant_id': merchantId},
    );
    final json = response.data as Map<String, dynamic>;
    final rawEvents = json['events'] as List<dynamic>? ?? const <dynamic>[];
    return rawEvents
        .cast<Map<String, dynamic>>()
        .map(OrderEvent.fromWireJson)
        .whereType<OrderEvent>()
        .toList();
  }
}

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return OrdersHistoryApi(httpClient);
});
```

Calls `GET /webhooks/events?merchant_id=<merchantId>`, decodes the
`events` array, maps each item through `OrderEvent.fromWireJson`, drops
nulls (unrecognized types / bad rows).

### 4. `OrderEventsDao.getOrder` (new, `core/database/daos/order_events_dao.dart`)

```dart
Future<OrderEventsTableData?> getOrder(String orderId, String storeId) {
  return (select(orderEventsTable)
        ..where((t) => t.orderId.equals(orderId) & t.storeId.equals(storeId)))
      .getSingleOrNull();
}
```

Needed so `saveIfNewer` (below) can look up what's already stored before
deciding whether to overwrite it.

### 5. `shouldReplaceStoredOrder` (new, `features/live_orders/use_cases/should_replace_stored_order.dart`)

```dart
bool shouldReplaceStoredOrder({required OrderData? existing, required OrderData incoming}) {
  if (existing == null) return true;
  return !incoming.updatedAt.isBefore(existing.updatedAt);
}
```

`null` existing always replaces; otherwise only when `incoming` isn't
older than `existing` (ties go to `incoming`, since re-writing identical
data is harmless).

### 6. `latestEventPerOrder` (new, `features/live_orders/use_cases/latest_event_per_order.dart`)

```dart
List<OrderEvent> latestEventPerOrder(List<OrderEvent> events) {
  final byOrderId = <String, OrderEvent>{};
  for (final event in events) {
    final current = byOrderId[event.data.id];
    if (current == null || !event.data.updatedAt.isBefore(current.data.updatedAt)) {
      byOrderId[event.data.id] = event;
    }
  }
  return byOrderId.values.toList();
}
```

Collapses the REST history's full per-event log down to one `OrderEvent`
per `orderId` before persisting.

### 7. "Write if newer" persistence (`OrderEventsLocalRepository.saveIfNewer`, in `repositories/order_events_local_repository.dart`)

The existing `save()` (used by the live socket, returns
`Result<void, AppError>`) is unconditional — last write always wins — and
stays that way; live events are always trusted. A new
`saveIfNewer(OrderEvent event, {required String storeId})` is added for
REST-sourced events, matching the same `Result<void, AppError>` return
convention as `save()`:

```dart
@override
Future<Result<void, AppError>> saveIfNewer(OrderEvent event, {required String storeId}) async {
  try {
    final existingRow = await _dao.getOrder(event.data.id, storeId);
    final existing = existingRow == null
        ? null
        : OrderData.fromJson(jsonDecode(existingRow.payload) as Map<String, dynamic>);
    if (!shouldReplaceStoredOrder(existing: existing, incoming: event.data)) {
      return const Success(null);
    }
    return save(event, storeId: storeId);
  } catch (e) {
    return Failure(DatabaseError(e.toString()));
  }
}
```

This is what prevents a REST backfill from overwriting an order the live
socket just updated.

### 8. Backfill algorithm (`_syncHistory`, private helper on `OrdersFeedNotifier`, reused by both callers below)

Given a `storeId`:
1. `OrdersHistoryApi.fetchEvents(storeId)`.
2. `latestEventPerOrder` to collapse to one event per order.
3. `saveIfNewer` each surviving event into the local DB.
4. Any failure (network, parse) is caught and `debugPrint`-logged, matching
   `OrdersFeedNotifier._connect()`'s existing best-effort error handling —
   the screen keeps showing whatever's already persisted.

### 9. Wiring

- **`OrdersFeedNotifier._connect(storeId)`**: `await _syncHistory(storeId)`
  right after `_storeId = storeId` is set, before opening the WS session.
  Because `build()` already reruns on every fresh login (via
  `ref.watch(storeInfoProvider.future)`) and every `storeInfoProvider`
  rebuild (which `StoreInfoNotifier.save()` — the store-settings save path
  — already triggers), this covers "after login" and "after saving store
  settings" with no new call sites there.
- **`OrdersFeedNotifier.refreshHistory()`** (new public method): re-runs
  `_syncHistory` against the already-known `_storeId`, without touching
  the socket connection. No-ops if `_storeId` is `null` (not currently
  logged in / no store ID yet).
- **`OrdersScreen`**: calls `refreshHistory()` once on mount (`useEffect`),
  and wraps the order `ListView.separated` in a `RefreshIndicator` that
  calls the same method for pull-to-refresh (the screen has no
  `RefreshIndicator` today). The empty state (`EmptyStateWidget`) is left
  outside the `RefreshIndicator`, matching the kiosk's equivalent
  (`_EmptyBody` un-wrapped) — pull-to-refresh isn't reachable with zero
  rows either way.

## Data flow summary

```
Login / store settings save
        │
        ▼
OrdersFeedNotifier.build() → _connect(storeId)
        │
        ├─ await _syncHistory(storeId)   [REST backfill, write-if-newer]
        │
        └─ open WS session → live events via save() [unconditional]

Orders screen mount / pull-to-refresh
        │
        ▼
OrdersFeedNotifier.refreshHistory() → _syncHistory(storeId)
        (socket untouched, no reconnect flicker)
```

Both paths write into the same `order_events` table that
`persistedOrdersProvider` / `pendingOrdersCountProvider` already stream
from, so no screen-level plumbing changes beyond the mount hook +
`RefreshIndicator`.

## Error handling

- No store ID resolvable yet → skip silently (mirrors the existing
  `!authed || storeId.isEmpty` fallback in `build()`/`checkConnection()`).
- REST call fails (offline, 5xx, timeout) → caught, logged, no user-facing
  error — the live socket and existing local cache remain the actual
  source of correctness; this is a best-effort enrichment, not a required
  load.
- Malformed/unrecognized event rows are skipped individually, not fatal to
  the whole batch (same as the WS parser today).

## Testing

- Unit test `OrderEvent.fromWireJson`: valid `order.created`/`updated`/`cancelled`,
  unrecognized `event_type` → `null`, malformed `data` → `null`.
- Unit test `shouldReplaceStoredOrder`: no existing order (replace),
  existing with older `updatedAt` (replace), existing with newer or equal
  `updatedAt` (don't replace).
- Unit test `latestEventPerOrder`: multiple events for the same `orderId`
  collapse to the one with the latest `updatedAt`.
- Manual verification in the running mobile app:
  - Fresh login → previously-placed orders (from the REST history) appear
    on the Orders screen.
  - Change store ID via store settings save → old store's orders clear
    from view, new store's history loads.
  - Pull down on the Orders screen → re-fetch happens with no visible
    socket reconnect/flicker.
  - While the socket is live and an order updates in real time, trigger a
    pull-to-refresh at the same moment — the real-time update is not
    reverted by the backfill.

## Out of scope

- Backend (`be/`) — no API changes needed, endpoint already exists.
- Kiosk (`kiosk/`) — already implemented; untouched by this change.
- Pagination of the `/webhooks/events` response — same assumption the
  kiosk design made; a follow-up if the real endpoint paginates.
- Changing the live socket's `save()` semantics, the pending-badge query
  logic, or `OrderEventsTable.updatedAt`'s current (non-refreshing) update
  behavior — unaffected by / unrelated to this change.
- A shared `httpClientProvider` abstraction across REST clients — mobile
  has exactly one REST client after this change, so there's nothing to
  share yet.
