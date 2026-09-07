# Live order-events receive path for `mobile_merchant`

**Date:** 2026-09-07
**Status:** approved (pending spec review)
**Scope:** the WebSocket **receive** path only — parsing incoming frames, de-duping,
persisting, updating in-app state, and raising both an OS local notification and
an in-app toast per event.
Out of scope: connection lifecycle / backoff, auth/token, device registration,
REST `fetchOrders` / `refresh`, and anything on the send/emit side.

---

## 1. Problem

`mobile_merchant`'s live feed currently treats the socket as a "something changed"
signal: `OrdersFeedNotifier._onMessage` receives a raw `String` frame and calls
`ref.invalidate(ordersProvider)`, forcing a full REST reload of the order list on
every event.

The `mobile` app handles the same feed differently: it parses each frame into a
typed event, de-dupes by `event_id`, persists every event to the local DB
(upsert keyed by order id), prepends it to an in-memory feed, and — per event —
shows an in-app toast and raises one OS local notification. No REST reload.

This change ports `mobile`'s **receive** flow to `mobile_merchant`, adapted to
`mobile_merchant`'s existing types (`OrderEventDto`, `OrdersNotifier`,
`OrderEventsDao`).

## 2. Wire contract (confirmed)

Reference: `docs/kiosk-websocket-implementation.md` and
`docs/superpowers/specs/2026-08-24-orders-history-backfill-design.md`.

Each WS text frame is JSON:

```json
{
  "event_id": "evt_…",
  "event_type": "order.created" | "order.updated" | "order.cancelled",
  "data": { "...OrderData fields, snake_case..." }
}
```

- The REST `GET /merchant/orders` payload is a **superset** of this: it wraps
  `id` (int), `received_at`, `created_at` around the same three keys. So
  `mobile_merchant`'s existing `OrderEventDto.fromJson` (which requires those
  wrapper fields) cannot parse a WS frame — a separate lenient factory is needed.
- `event_type` values are the dotted form (`order.created`) on **both** WS and
  REST, so no normalization mismatch with existing stored data.
- Unknown `event_type` outside `order.*` (`payment.*`, `inventory.updated`) →
  dropped. Any other `order.*` (e.g. `order.fulfilled`) → kept, treated as an
  update.
- Redelivery is possible — the client must de-dupe by `event_id`.

## 3. Design

### 3.1 Lenient wire factories — `features/orders/data/models/`

Add wire factories alongside the existing strict REST `fromJson` (left
untouched, so the REST contract stays strict — mirrors `mobile`'s
`fromJson` / `fromWireJson` split):

**`OrderEventDto.fromWireJson(Map<String, dynamic>) → OrderEventDto?`**
- Returns `null` (never throws) when: `event_type` is absent / not `order.*`;
  `event_id` is absent or empty; `data` is not a map; `data` has no `id`.
- Synthesizes the fields the wire frame lacks:
  - `id` = `DateTime.now().microsecondsSinceEpoch` — a value far larger than any
    real remote row id (which are small sequential ints), so a live row sorts
    ahead of / outranks a stale cached row in `orders_body`'s id-based views.
  - `receivedAt` = now.
  - `createdAt` = `data.created_at` parsed, else now.

**`OrderDataDto.fromWireJson(Map<String, dynamic>)`**
- Only `id` is required (missing → throws → caught by `fromWireJson` → event
  dropped). Every other field falls back to a sane default (`''`, `null`,
  `'unknown'`, `0`, epoch), so one odd field never drops an otherwise-usable
  order. `total` tolerates an int or double. `created_at` / `updated_at` each
  fall back to the other then to epoch.

**`OrderItemDto.fromWireJson(Map<String, dynamic>)`**
- Every field falls back (`''`, `1` for quantity, `0` for price), so one bad
  line item can't drop the whole order. Non-map entries in `items` are skipped.

### 3.2 Frame parser — `features/orders/data/repositories/orders_live_feed_repository.dart`

Extract the string-frame → DTO step as a **top-level pure function** so it is
directly unit-testable (mirrors the `_parse` extraction noted in the
2026-08-24 backfill spec):

```dart
OrderEventDto? parseOrderEventFrame(Object? raw) {
  if (raw is! String) { debugPrint('[OrdersFeed] dropped non-string frame: $raw'); return null; }
  final Map<String, dynamic> json;
  try { json = jsonDecode(raw) as Map<String, dynamic>; }
  catch (e) { debugPrint('[OrdersFeed] bad JSON frame: $raw ($e)'); return null; }
  final event = OrderEventDto.fromWireJson(json);
  if (event == null) debugPrint('[OrdersFeed] unrecognized/unparseable frame: $raw');
  return event;
}
```

`OrdersSocketSession` / `OrdersLiveFeedRepository` change:
- `OrdersSocketSession.messages : Stream<String>` → `events : Stream<OrderEventDto>`.
- `connect()` maps `channel.stream` through `parseOrderEventFrame`,
  `.where((e) => e != null).cast<OrderEventDto>()`.
- The `channel.ready` debug log and single-attempt semantics are unchanged.

### 3.3 Feed notifier — `features/orders/state/orders_feed_notifier.dart`

- `_subscription` → `StreamSubscription<OrderEventDto>?`; `session.events.listen(_onEvent, …)`.
- Add bounded de-dupe state, copied verbatim from `mobile`:
  ```dart
  final Queue<String> _recentEventIds = Queue();
  final Set<String>  _seenEventIds  = {};
  ```
- Replace `_onMessage(String)` with:
  ```dart
  void _onEvent(OrderEventDto event) {
    if (!_seenEventIds.add(event.eventId)) return;           // duplicate delivery
    _recentEventIds.add(event.eventId);
    if (_recentEventIds.length > 200) {
      _seenEventIds.remove(_recentEventIds.removeFirst());
    }
    showOrderToast(event);                                        // in-app snackbar, best-effort
    unawaited(getIt<OrderNotificationsService>().notify(event));  // OS notification, best-effort, never awaited
    final merchantId = _merchantId;
    if (merchantId != null) {
      unawaited(ref.read(ordersProvider.notifier).applyLiveEvent(event, merchantId));
    }
  }
  ```
- `_teardown()` also clears `_recentEventIds` / `_seenEventIds`.
- **Nothing else changes** — `_connect`, backoff, `_readyTimeout`, connectivity
  handling, token minting all stay exactly as they are.
- The now-unused `ref.invalidate(ordersProvider)` line is removed.

### 3.4 `OrdersNotifier.applyLiveEvent` — `features/orders/state/orders_notifier.dart`

```dart
Future<void> applyLiveEvent(OrderEventDto event, String merchantId) async {
  try {
    await getIt<AppDatabase>().orderEventsDao.upsertLiveEvent(merchantId, event);
  } catch (e, s) {
    AppLogger.logError('OrdersNotifier.applyLiveEvent', e, s);  // DB failure must not lose the UI update
  }
  final current = state.value;
  if (current == null) return;   // build() not resolved yet — DB write still landed
  state = AsyncData(
    OrdersState(events: mergeLiveOrderEvent(current.events, event), isStale: current.isStale),
  );
}
```

The list merge is a **top-level pure function** (testable, keeps the notifier thin):

```dart
List<OrderEventDto> mergeLiveOrderEvent(List<OrderEventDto> current, OrderEventDto incoming) =>
    [incoming, ...current.where((e) => e.data.id != incoming.data.id)];
```

Explicit merge by `data.id` (drop any existing entry for that order, prepend the
new one) — does not rely on `orders_body`'s "highest `id` wins" de-dupe, so an
`updated` / `cancelled` event replaces the row correctly too.

### 3.5 DAO — `OrderEventsDao.upsertLiveEvent` — `core/database/daos/order_events_dao.dart`

```dart
Future<void> upsertLiveEvent(String merchantId, OrderEventDto event) async {
  await transaction(() async {
    final existing = await (select(orderEventsTable)
          ..where((t) => t.orderId.equals(event.data.id) & t.merchantId.equals(merchantId)))
        .getSingleOrNull();
    final rowId = existing?.id ?? event.id;   // keep the real remote id on update; synthetic id on insert

    if (existing != null) {
      await (update(orderEventsTable)..where((t) => t.id.equals(rowId))).write(
        OrderEventsTableCompanion(
          eventId:        Value(event.eventId),
          eventType:      Value(event.eventType),
          receivedAt:     Value(event.receivedAt.toIso8601String()),
          customerName:   Value(event.data.customerName),
          customerEmail:  Value(event.data.customerEmail),
          orderStatus:    Value(event.data.status),
          orderTotal:     Value(event.data.total),
          currency:       Value(event.data.currency),
          orderUpdatedAt: Value(event.data.updatedAt.toIso8601String()),
        ),
      );
      await (delete(orderItemsTable)..where((t) => t.eventId.equals(rowId))).go();
    } else {
      await into(orderEventsTable).insert(OrderEventsTableCompanion.insert(
        id: Value(rowId),
        eventId: event.eventId,
        eventType: event.eventType,
        receivedAt: event.receivedAt.toIso8601String(),
        createdAt: event.createdAt.toIso8601String(),
        merchantId: merchantId,
        orderId: event.data.id,
        customerId: event.data.customerId,
        customerName: Value(event.data.customerName),
        customerEmail: Value(event.data.customerEmail),
        orderStatus: event.data.status,
        orderTotal: event.data.total,
        currency: event.data.currency,
        orderCreatedAt: event.data.createdAt.toIso8601String(),
        orderUpdatedAt: event.data.updatedAt.toIso8601String(),
      ));
    }

    for (final item in event.data.items) {
      await into(orderItemsTable).insert(OrderItemsTableCompanion.insert(
        eventId: rowId,
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        price: item.price,
      ));
    }
  });
}
```

- One row per order (`orderId` + `merchantId`), latest event wins — same
  invariant `_deduplicateByOrderId` in `orders_body` already assumes.
- `merchantId` comes from the caller (the feed notifier's authoritative
  `_merchantId`), not from `event.data.merchant_id`, which may be blank.
- **Reconciliation:** the next full REST fetch runs `replaceAll`, which wipes
  every row for the merchant and re-inserts the server response with real
  remote ids. A live-only order not yet in that response is briefly dropped
  then reappears on the following sync — identical to `mobile`'s documented
  behavior.
- On an **update** the row keeps its existing `id`, so any pagination cursor
  built on `id` stays valid and the card updates in place rather than jumping
  to the top of the list.

### 3.6 Local notification — `core/services/notifications/order_notifications_service.dart`

Port `mobile`'s `OrderNotificationsService` (one local notification per received
event, best-effort — a failure here never touches the feed):

- New dependency: `flutter_local_notifications: ^22.3.0` (matches `mobile`).
- Class registered with `@lazySingleton` (injectable). `initialize()` is called
  once from `bootstrap()` after `configureDependencies()` and before `runApp`
  (same shape as the existing `getIt<SettingsService>().init()` call) — it sets
  up the Android channel and requests the Android-13+ runtime permission, all
  wrapped in try/catch.
- Title / body mapping is a **top-level pure function** for testability:
  ```dart
  ({String title, String body}) orderNotificationText(OrderEventDto e) {
    final d = e.data;
    return switch (e.eventType) {
      'order.created'   => (title: 'New order #${d.id}',
                            body: '${d.items.length} item${d.items.length == 1 ? '' : 's'} · ${d.currency} ${d.total.toStringAsFixed(2)}'),
      'order.cancelled' => (title: 'Order #${d.id} cancelled', body: ''),
      _                 => (title: 'Order #${d.id} updated', body: 'Status: ${d.status}'),
    };
  }
  ```
- `notify(OrderEventDto)` builds text via `orderNotificationText`, then
  `_plugin.show(id: event.eventId.hashCode, …)` inside try/catch.

### 3.7 In-app toast — `core/notifications/order_toast.dart` (new)

A snackbar shown for every received event while the app is foregrounded —
complements the OS notification (which covers the backgrounded case).

- New global key in `core/router/app_router.dart` (next to the existing
  `appNavigatorKey`):
  ```dart
  final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  ```
- `App` (`lib/app.dart`) passes it to `MaterialApp.router(scaffoldMessengerKey: appScaffoldMessengerKey, …)`.
- `order_toast.dart`:
  ```dart
  void showOrderToast(OrderEventDto event) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;                 // no UI mounted yet — silently skip
    final (:title, :body) = orderNotificationText(event);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(body.isEmpty ? title : '$title · $body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }
  ```
  Reuses `orderNotificationText` (defined in the notifications service, §3.6) so
  the OS notification and the toast never drift apart.
- Kept separate from the existing `shared/widgets/app_snackbar.dart` (which is
  `BuildContext`-based) so routing/global-key coupling stays out of that helper.

**Android platform config** (`mobile_merchant/android/`):
- `app/build.gradle.kts` — enable core-library desugaring
  (`flutter_local_notifications` ≥ 18 requires it):
  ```kotlin
  compileOptions { isCoreLibraryDesugaringEnabled = true /* + existing 17/17 */ }
  dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
  ```
- `app/src/main/AndroidManifest.xml` — add
  `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.
- Only `_plugin.show()` is used (no scheduling), so no extra `<receiver>`
  entries are needed.

> **Verification caveat:** the Android Gradle changes cannot be verified by
> `dart analyze` and this workflow does not run a full `flutter build apk`.
> They are copied from a known-good `flutter_local_notifications` setup; a real
> Android build is the acceptance check for that slice.

## 4. Data flow (after the change)

```
WS text frame
  └─ OrdersLiveFeedRepository.connect → parseOrderEventFrame → Stream<OrderEventDto>
       └─ OrdersFeedNotifier._onEvent
            ├─ de-dupe by event_id (bounded 200-entry ring)
            ├─ showOrderToast(event)                            (in-app snackbar, best-effort)
            ├─ OrderNotificationsService.notify(event)          (OS notification, best-effort, fire-and-forget)
            └─ OrdersNotifier.applyLiveEvent(event, merchantId)
                 ├─ OrderEventsDao.upsertLiveEvent  (1 row/order, items replaced)
                 └─ state = AsyncData(mergeLiveOrderEvent(current, event))
                      └─ orders_body rebuilds — no REST call
```

## 5. Testing

New tests under `mobile_merchant/test/features/orders/` — every piece of new
**pure** logic is covered; the two impure edges (`_plugin.show`, the Gradle
config) are best-effort / build-verified and called out above.

1. **`data/models/order_event_dto_wire_test.dart`** — `OrderEventDto.fromWireJson`:
   valid `order.created` / `order.updated` / `order.cancelled`; unknown
   `event_type` → `null`; missing / empty `event_id` → `null`; `data` without
   `id` → `null`; ignores REST-only wrapper keys (`id`, `received_at`) when
   present; synthesizes a positive `id` and a `receivedAt`.
2. **`data/models/order_data_dto_wire_test.dart`** — `OrderDataDto.fromWireJson` /
   `OrderItemDto.fromWireJson`: missing optional fields fall back; `total` as
   int and as double; a malformed line item still yields an item with defaults;
   non-map `items` entries skipped.
3. **`data/repositories/order_event_frame_parser_test.dart`** —
   `parseOrderEventFrame`: non-`String` input → `null`; invalid JSON → `null`;
   a JSON array (not object) → `null`; a valid frame → the expected DTO.
4. **`state/merge_live_order_event_test.dart`** — `mergeLiveOrderEvent`: a new
   order id is prepended; an existing order id is replaced (list length
   unchanged, new event at head, old entry gone); empty starting list.
5. **`core/services/notifications/order_notification_text_test.dart`** —
   `orderNotificationText`: the three branches (created / updated / cancelled),
   singular vs plural "item(s)", total formatting. (Covers the toast string too —
   `showOrderToast` composes `title` / `body` from this function; the
   `ScaffoldMessengerState`-null early return is exercised by calling
   `showOrderToast` with no key attached and asserting it does not throw.)
6. **`data/daos/order_events_dao_upsert_test.dart`** — using
   `AppDatabase.withExecutor(NativeDatabase.memory())` (the sanctioned in-memory
   test ctor): inserting a new live event creates one row + its items;
   a second event for the **same** order updates the row in place (still one
   row, `orderStatus` changed, items replaced) and keeps the original `id`;
   events for two merchants with the same `orderId` stay separate.
   *If the local `flutter test` toolchain cannot load `sqlite3` for
   `NativeDatabase.memory()`, this file is the one acceptable omission — the
   merge/parse tests plus a manual run remain the coverage.*

Run: `flutter test` (from `mobile_merchant/`). Static check: `dart analyze`.
After the `pubspec.yaml` + `@lazySingleton` additions:
`flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`.

## 6. File-change summary

| File | Change |
|---|---|
| `features/orders/data/models/order_event_dto.dart` | + `fromWireJson` |
| `features/orders/data/models/order_data_dto.dart` | + `fromWireJson` |
| `features/orders/data/models/order_item_dto.dart` | + `fromWireJson` |
| `features/orders/data/repositories/orders_live_feed_repository.dart` | `messages`→`events` typed stream; + top-level `parseOrderEventFrame` |
| `features/orders/state/orders_feed_notifier.dart` | typed subscription; de-dupe ring; `_onEvent` replaces `_onMessage`; toast + notify + `applyLiveEvent` dispatch; no more `ref.invalidate` |
| `features/orders/state/orders_notifier.dart` | + `applyLiveEvent`; + top-level `mergeLiveOrderEvent` |
| `core/database/daos/order_events_dao.dart` | + `upsertLiveEvent` |
| `core/services/notifications/order_notifications_service.dart` | **new** — ported service + top-level `orderNotificationText` |
| `core/notifications/order_toast.dart` | **new** — `showOrderToast` via global `ScaffoldMessengerState` key |
| `core/router/app_router.dart` | + `appScaffoldMessengerKey` |
| `lib/app.dart` | `MaterialApp.router(scaffoldMessengerKey: appScaffoldMessengerKey)` |
| `lib/bootstrap.dart` | `await getIt<OrderNotificationsService>().initialize();` |
| `pubspec.yaml` | + `flutter_local_notifications: ^22.3.0` |
| `android/app/build.gradle.kts` | core-library desugaring |
| `android/app/src/main/AndroidManifest.xml` | + `POST_NOTIFICATIONS` |
| `core/di/injection.config.dart` | regenerated (build_runner) |
| `test/features/orders/**`, `test/core/**` | new test files (§5) |

## 7. Risks / tradeoffs

- **Synthetic `id` for new live orders.** Microsecond-epoch value; collision
  needs two inserts of *different* orders in the same microsecond (same-order
  goes through the update path). Reconciled away on the next REST `replaceAll`.
- **`applyLiveEvent` when `ordersProvider` has no listener.** `ref.read(
  ordersProvider.notifier)` instantiates the notifier; if `build()` hasn't
  resolved, `state.value` is `null` and only the DB write lands. The list
  catches up when the Orders screen mounts and `build()` runs its REST fetch.
  Acceptable and matches `mobile`.
- **Android build config unverifiable here** — see §3.6 caveat.
- **Toast + OS notification both fire for every event type** (created / updated /
  cancelled), so a burst of updates is chatty by design. `showOrderToast` calls
  `hideCurrentSnackBar()` first, so toasts replace rather than queue.
- **`appScaffoldMessengerKey` before first frame.** `showOrderToast` no-ops when
  `currentState` is null (app not yet mounted / between route rebuilds); the OS
  notification still fires and the list still updates.
