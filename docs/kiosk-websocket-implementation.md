# Kiosk WebSocket Implementation (Orders Live Feed)

Reference doc for porting the kiosk's live-orders WebSocket feed to the mobile app.

## Summary

The kiosk keeps one raw WebSocket connection open (not Socket.IO) to an
external "webhook-receiver" service, scoped to the logged-in cashier's kiosk.
It streams `order.created` / `order.updated` / `order.cancelled` events,
which drive: an in-memory live feed, a local (on-disk) latest-state-per-order
cache used for a pending-orders badge, a connection-status banner, and toast
notifications for new orders.

- Transport: `package:web_socket_channel` (plain WS, JSON text frames) — **not** `socket_io_client`.
- Endpoint: `<ORDERS_LIVE_FEED_WS_URL>/ws?merchant_id=<kioskId>`
- Reconnect: manual exponential backoff (1s → 30s cap), driven by app code, not by the socket library.
- Lifecycle: session-scoped (connects once logged in, stays connected regardless of screen), not screen-scoped.

## File map

```
lib/config/environment/
  app_env.dart                         # AppEnv.ordersLiveFeedWsUrl (+ env.dart / env_dev.dart impls, Envied-generated)

lib/features/orders/
  repositories/orders_live_feed_repository.dart   # raw WS connection + JSON parsing
  repositories/order_events_local_repository.dart # Drift-backed persistence of latest event per order
  entities/order_event.dart                       # OrderEvent / OrderEventType / OrderData wire model (dart_mappable)
  entities/orders_feed_state.dart                 # OrdersFeedState / OrdersFeedConnection enum
  state/orders_feed_notifier.dart                 # connection lifecycle, reconnect/backoff, event dedupe
  state/pending_orders_count_provider.dart         # kioskId resolution + badge/list providers sourced from local DB

lib/core/connectivity/connectivity_status_provider.dart  # isOnlineProvider (link-level, via connectivity_plus)
lib/core/database/tables/order_events_table.dart          # Drift table (1 row per order, latest event wins)
lib/core/database/daos/order_events_dao.dart               # upsert / watchPendingCount / watchOrders / deleteAll

lib/widgets/connectivity_status_banner.dart   # UI: offline / connecting / reconnecting banner
lib/app.dart                                   # wires the notifier app-wide; toast on connect + on new order
```

## 1. Environment config

`AppEnv.ordersLiveFeedWsUrl` — declared in `lib/config/environment/app_env.dart`, backed by an
Envied `@EnviedField()` on `Env`/`EnvDev`, sourced from `.env` (`ORDERS_LIVE_FEED_WS_URL`).
This is a **separate** base URL from the main backend (`backendApiBaseUrl`) — the live feed talks
to an external webhook-receiver service, independent of the POS backend.

## 2. Repository — the connection itself

`OrdersLiveFeedRepository` (`orders_live_feed_repository.dart`) is a thin, stateless factory:
each call to `connect(kioskId)` opens exactly **one** connection attempt and returns an
`OrdersSocketSession`. It does not retry — the caller (the notifier) owns reconnect/backoff.

```dart
OrdersSocketSession connect(String kioskId) {
  final uri = Uri.parse('$_baseUrl/ws').replace(queryParameters: {'merchant_id': kioskId});
  final channel = WebSocketChannel.connect(uri);
  final events = channel.stream.map(_parse).where((e) => e != null).cast<OrderEvent>();
  return OrdersSocketSession(channel, events);
}
```

- `OrdersSocketSession.ready` — a `Future<void>` (`channel.ready`) that resolves once the socket
  is actually open, or throws. Used to distinguish "still connecting" from "dead network" instead
  of hanging indefinitely.
- `OrdersSocketSession.close()` — closes the sink.
- Each incoming frame is expected to be a JSON **string** (non-string frames are dropped and logged).

### Wire message shape

```json
{
  "event_id": "string",
  "event_type": "order.created" | "order.updated" | "order.cancelled",
  "data": { "...": "OrderData fields, snake_case" }
}
```

- `event_type` values outside the 3 recognized ones (e.g. `payment.*`, `inventory.updated`) are
  silently dropped via `OrderEventType.fromWire` returning `null`.
- Parse failures (bad JSON, missing fields) are caught, logged, and dropped — a malformed message
  never crashes the stream.
- `OrderData` uses `@MappableClass(caseStyle: CaseStyle.snakeCase)` (dart_mappable) to map the
  snake_case wire payload to Dart fields. `fulfillmentType` uses `defaultValue: FulfillmentType.other`
  so unrecognized values (e.g. sandbox `"TEST"`) don't crash parsing.

## 3. State notifier — connection lifecycle, reconnect, dedupe

`OrdersFeedNotifier` (`AsyncNotifier<OrdersFeedState>`) is the orchestrator. Key behaviors to
replicate on mobile:

**Session-scoped, not screen-scoped.** `ref.keepAlive()` + watching `loginStateProvider` means it
connects once a user logs in and stays connected app-wide, independent of which screen is active —
so an order isn't missed just because nobody has the orders screen open. It's watched once, in the
app root (`app.dart`), not per-screen.

**Connect flow (`_connect`)**:
1. Resolve `kioskId` via `posTerminalsApiProvider.getMyTerminal()` (a REST call — the kiosk ID isn't
   known statically, it's this terminal's registered ID).
2. `repository.connect(kioskId)`.
3. `await session.ready.timeout(_readyTimeout)` — 10s timeout guards against a hung handshake.
4. On success: subscribe to `session.events` with `onError`/`onDone` both routed to the same
   `_onDrop` handler, mark `OrdersFeedConnection.connected`, record `_connectedAt`.
5. On any failure (terminal lookup, connect, or ready-timeout): close whatever session exists,
   mark `reconnecting`, schedule a retry.

**Backoff**: starts at 1s, doubles each failed attempt, caps at 30s. Resets back to 1s only if the
connection had been stable for > 5s before dropping (`_stableConnectionThreshold`) — this avoids
punishing a connection that was healthy for a while with a maxed-out backoff after one blip, while
still backing off hard on a socket that fails immediately/repeatedly.

**Connectivity-aware reconnect**: separately listens to `isOnlineProvider` (link-level network
state via `connectivity_plus`, not app-reachability). When the device transitions offline→online
while the socket is `reconnecting`/`disconnected`, it reconnects immediately instead of waiting out
whatever backoff delay is still in flight.

**Event dedupe**: keeps a bounded `Queue<String>` + `Set<String>` of the last 200 `eventId`s seen,
to drop duplicate deliveries (the underlying service can redeliver). Both structures are trimmed
together when the queue exceeds 200.

**Teardown** (on logout / dispose): cancels the retry timer, cancels the event subscription, closes
the session, resets backoff and connectedAt — so a fresh login starts clean.

`OrdersFeedConnection` enum: `disconnected | connecting | connected | reconnecting`.

## 4. Local persistence (survives restarts, independent of live-feed state)

Every event — not just `created` — is persisted via `OrderEventsLocalRepository` → Drift DAO,
**upserting by `orderId`** so a later `updated`/`cancelled` overwrites the row `created` made. This
is what actually backs a "pending orders" badge/count, not the in-memory feed — so the badge is
correct immediately on app launch, before any socket connects, and stays correct through
disconnects.

`OrderEventsTable`: one row per order (`orderId` primary key) — `kioskId`, `eventType`, `payload`
(JSON), `updatedAt`. "Pending" = latest `eventType != 'cancelled'`.

`pending_orders_count_provider.dart` layers on top: `resolvedKioskIdProvider` prefers the feed
notifier's already-known `kioskId` (avoids an extra REST call) and falls back to a direct terminal
lookup — so the badge works even if the socket is offline or hasn't connected yet.

## 5. UI wiring

- **`app.dart`** watches `ordersFeedNotifierProvider` once at the app root — this is what actually
  boots the connection (the notifier is otherwise inert until watched). Two `ref.listen`s:
  - Toast "Connected to live orders (kiosk: X)" on transition into `connected` (not on every
    rebuild — only on the `wasConnected: false → isConnected: true` edge).
  - Toast "New order #id · N item(s)" per new `order.created` event, computed by diffing the new
    event list's head against the previous head's `eventId` (the feed prepends, so anything ahead
    of the old head is new).
- **`ConnectivityStatusBanner`** — combines `isOnlineProvider` (device link state) with the socket's
  `OrdersFeedConnection`. Offline always wins over the socket enum, since a dropped interface
  eventually surfaces as `reconnecting` anyway but with a less specific message. Shows nothing when
  fully connected.

## Porting notes for mobile

1. **Not Socket.IO** — this is a plain WebSocket with a custom JSON envelope
   (`event_id`/`event_type`/`data`), so no `socket_io_client` dependency is needed; any WS client
   works as long as reconnect/backoff is handled manually (mobile's client library may already do
   this — check before reimplementing).
2. **Auth/scoping is via query param**, not a handshake payload: `?merchant_id=<kioskId>`, where
   `kioskId` comes from `GET` terminal-lookup, not from local auth state directly.
3. **Reconnect must be app-level**, not delegated to the socket layer: this app's backoff, the
   "stable-for-5s resets backoff" rule, and the ready-timeout are all hand-rolled around a
   single-attempt `connect()`. `web_socket_channel` has no built-in reconnect.
4. **Persist every event type**, keyed by order id with upsert-latest-wins, if mobile needs a
   restart-durable pending count — don't only persist `created`.
5. **Dedupe by `event_id`** — the upstream service can redeliver; don't assume at-most-once.
6. **Decide session vs. screen scope deliberately.** The kiosk deliberately keeps this connected
   for the whole logged-in session so no order is missed. If mobile only needs live orders while a
   specific screen is open, that's a meaningfully different (simpler) lifecycle — worth confirming
   which behavior mobile actually wants before porting the session-scoped pattern as-is.
7. Mobile should treat `isOnlineProvider`-equivalent (link-level connectivity) and socket connection
   state as two separate signals, as the kiosk does — don't conflate "no wifi" with "socket dropped
   for another reason" in the UI, since the two have different remedies for the user.
