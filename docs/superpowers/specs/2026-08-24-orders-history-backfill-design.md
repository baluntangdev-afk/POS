# Orders history backfill (REST) — design

## Problem

The kiosk's Orders screen and pending-orders badge are backed entirely by
events the live WebSocket feed (`OrdersFeedNotifier`) has received since the
app last connected. If the kiosk was offline, freshly installed, or just
switched to a new kiosk ID, it has no way to see orders that happened before
the socket connected. The webhook-receiver now exposes a REST history
endpoint that returns every event for a merchant:

```
GET https://<orders-live-feed-host>/webhooks/events?merchant_id=<kioskId>
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

Use this endpoint to backfill the kiosk's local order history:
- once after login,
- once after the kiosk ID changes via the terminal-settings dialog,
- on entering the Orders screen, and via swipe-to-refresh on that screen,

without let it clobber fresher state the live socket has already written.

## Where the endpoint lives

The endpoint is on the same webhook-receiver host as `ORDERS_LIVE_FEED_WS_URL`
(`dposocket.onrender.com` today), but **not** `CARTIVO_AUTH_API_BASE_URL` (a
different webhook-receiver deployment already used by `OrdersApi` for
order status/cancel). Rather than deriving the http(s) URL from the ws(s)
one at runtime, it gets its own dedicated env var, `ORDERS_EVENTS_API_BASE_URL`
(added to `AppEnv`/`Env`/`EnvDev`/`.env.sample`, value `https://dposocket.onrender.com`
in the local `.env`/`.env.dev`) — done.

## Components

### 1. `ordersEventsApiClientProvider` (new, in `api_clients.dart`)

Builds a `Dio` client whose `baseUrl` is `env.ordersEventsApiBaseUrl`.
Unauthenticated, same pattern as `cartivoApiClientProvider`.

### 2. Shared event parser (`OrderEvent.fromWireJson`, in `entities/order_event.dart`)

The JSON→`OrderEvent` parsing logic currently private to
`OrdersLiveFeedRepositoryImpl._parse` (read `event_type` via
`OrderEventType.fromWire`, `event_id`, `data` via `OrderData.fromJson`,
return `null` on an unrecognized `event_type` or parse failure) is extracted
into a static factory on `OrderEvent`. Both the WS repository and the new
REST source call it, so "what counts as a valid event" can't drift between
the two paths.

### 3. `OrdersHistoryApi` (new, in `data/backend_api/sources/`)

```dart
class OrdersHistoryApi {
  Future<List<OrderEvent>> fetchEvents(String merchantId);
}
```

Calls `GET /webhooks/events?merchant_id=<merchantId>` on the client from
(1), decodes the `events` array, maps each item through
`OrderEvent.fromWireJson`, drops nulls (unrecognized types / bad rows).

### 4. "Write if newer" persistence (`OrderEventsLocalRepository`)

The existing `save()` (used by the live socket) is unconditional — last
write always wins — and stays that way; live events are always trusted.

A new `saveIfNewer(OrderEvent event, {required String kioskId})` is added
for REST-sourced events: it reads the currently stored row for that
`orderId` (if any), compares `OrderData.updatedAt` on the stored payload
against the incoming event's, and only upserts when there's no existing row
or the incoming `updatedAt` is not older. This is what prevents a REST
backfill from overwriting an order the live socket just updated.

### 5. Backfill algorithm (`_syncHistory`, private helper reused by both callers below)

Given a `kioskId`:
1. `OrdersHistoryApi.fetchEvents(kioskId)`.
2. Reduce to one `OrderEvent` per `orderId`, keeping the one with the
   latest `data.updatedAt` (the endpoint returns the full event log, not
   just latest-per-order).
3. `saveIfNewer` each surviving event into the local DB.
4. Any failure (network, parse) is caught and `debugPrint`-logged, matching
   `OrdersFeedNotifier._connect()`'s existing best-effort error handling —
   the screen keeps showing whatever's already persisted.

### 6. Wiring

- **`OrdersFeedNotifier._connect()`**: after resolving `terminal.kioskId`
  and before opening the WS session, `await _syncHistory(kioskId)`. Because
  `_connect()` already runs on every fresh `build()` (login) and every
  provider invalidation (kiosk-ID change on settings save, which
  `PosTerminalDetailsDialog.onSave` already triggers), this covers "after
  login" and "after saving settings" with no new call sites there.
- **`OrdersFeedNotifier.refreshHistory()`** (new public method): re-runs
  `_syncHistory` against the already-known `_kioskId`, without touching the
  socket connection. No-ops if not currently logged in / no kiosk ID yet.
- **`OrdersScreen`**: calls `refreshHistory()` once on mount (`useEffect`),
  and wraps the kanban board region (the `Expanded` holding `_OrdersBody`)
  in a `RefreshIndicator` that calls the same method for swipe-to-refresh.
  `ScrollNotification`s from the per-column `AnimatedList`s bubble up to a
  single `RefreshIndicator` wrapping the whole board, so one indicator
  covers all columns.

## Data flow summary

```
Login / kiosk-ID change
        │
        ▼
OrdersFeedNotifier.build() → _connect()
        │
        ├─ await _syncHistory(kioskId)   [REST backfill, write-if-newer]
        │
        └─ open WS session → live events via save() [unconditional]

Orders screen mount / swipe-to-refresh
        │
        ▼
OrdersFeedNotifier.refreshHistory() → _syncHistory(kioskId)
        (socket untouched, no reconnect flicker)
```

Both paths write into the same `order_events` table that `persistedOrdersProvider`
/ `pendingOrdersCountProvider` already stream from, so no screen-level
plumbing changes beyond the mount hook + `RefreshIndicator`.

## Error handling

- No kiosk ID resolvable yet → skip silently (mirrors `resolvedKioskIdProvider`'s
  existing `null` fallback behavior).
- REST call fails (offline, 5xx, timeout) → caught, logged, no user-facing
  error — the live socket and existing local cache remain the actual source
  of correctness; this is a best-effort enrichment, not a required load.
- Malformed/unrecognized event rows are skipped individually, not fatal to
  the whole batch (same as the WS parser today).

## Testing

- Unit test `OrderEvent.fromWireJson`: valid `order.created`/`updated`/`cancelled`,
  unrecognized `event_type` → `null`, malformed `data` → `null`.
- Unit test `OrderEventsLocalRepository.saveIfNewer`: no existing row (writes),
  existing row with older `updatedAt` (writes), existing row with newer or
  equal `updatedAt` (no-op).
- Manual verification in the running kiosk app:
  - Fresh login → previously-placed orders (from the REST history) appear
    on the Orders screen.
  - Change kiosk ID in the terminal-settings dialog → old kiosk's orders
    clear, new kiosk's history loads.
  - Swipe down on the Orders screen → re-fetch happens with no visible
    socket reconnect/flicker.
  - While the socket is live and an order updates in real time, trigger a
    swipe-to-refresh at the same moment — the real-time update is not
    reverted by the backfill.

## Out of scope

- Mobile app (`mobile/`) — kiosk only, per request.
- Pagination of the `/webhooks/events` response — the sample payload shows
  no pagination cursor; if the real endpoint paginates, that's a follow-up.
- Changing the live socket's `save()` semantics or the pending-badge query
  logic — unaffected by this change.
