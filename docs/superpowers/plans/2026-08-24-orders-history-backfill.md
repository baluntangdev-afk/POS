# Orders History Backfill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backfill the kiosk's local order history from the webhook-receiver's `GET /webhooks/events` REST endpoint — on login, on kiosk-ID change (settings save), on Orders-screen mount, and via pull-to-refresh — without letting stale REST data overwrite fresher data the live WebSocket feed has already written.

**Architecture:** A new `OrdersHistoryApi` fetches and parses the REST event log (reusing the WS feed's JSON parsing, extracted into a shared `OrderEvent.fromWireJson`). A new `saveIfNewer` on the local order-events repository only overwrites a stored order if the incoming payload isn't older. `OrdersFeedNotifier` runs the backfill before opening its WebSocket session (covering login + kiosk-ID change for free, since both already trigger `_connect()`) and exposes a `refreshHistory()` for the Orders screen to call on mount and via `RefreshIndicator`.

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), Dio, Drift (local SQLite), `dart_mappable`.

**Reference spec:** `docs/superpowers/specs/2026-08-24-orders-history-backfill-design.md`

---

## Task 0: Env var (already done)

No action needed — this was completed during design review:
- `String get ordersEventsApiBaseUrl;` added to `lib/config/environment/app_env.dart`
- `ordersEventsApiBaseUrl` field added to `lib/config/environment/env.dart` and `lib/config/environment/env_dev.dart`
- `ORDERS_EVENTS_API_BASE_URL=` added to `.env.sample`, and `ORDERS_EVENTS_API_BASE_URL=https://dposocket.onrender.com` appended to the local `.env`/`.env.dev`
- `dart run build_runner build --delete-conflicting-outputs` already run successfully

- [x] **Step 1: Confirm the field exists**

Run: `grep -n "ordersEventsApiBaseUrl" lib/config/environment/app_env.dart`
Expected: `String get ordersEventsApiBaseUrl;`

---

## Task 1: Shared WS/REST event parser

**Files:**
- Modify: `lib/features/orders/entities/order_event.dart`
- Test: `test/features/orders/entities/order_event_test.dart`

The WS repository currently parses each message's JSON inline in
`OrdersLiveFeedRepositoryImpl._parse`. Both the WS feed and the new REST
fetch need identical "is this a valid order event" logic, so it moves onto
`OrderEvent` itself as a static factory.

- [ ] **Step 1: Write the failing test**

Create `test/features/orders/entities/order_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/orders/entities/order_event.dart';

Map<String, dynamic> _wireEvent({String eventType = 'order.created'}) => {
  'event_id': 'evt_test-1',
  'event_type': eventType,
  'data': {
    'id': 'ord_1',
    'customer_id': 'guest_1',
    'customer_name': null,
    'customer_email': null,
    'status': 'pending',
    'total': 100,
    'currency': 'PHP',
    'district_id': 'dist_1',
    'district_name': 'District One',
    'fulfillment_type': 'on_site',
    'facility_id': 'fac_1',
    'facility_name': 'Table 1',
    'created_at': '2026-08-21T06:35:14.918Z',
    'updated_at': '2026-08-21T06:35:14.918Z',
    'items': [
      {'product_id': 'item_1', 'product_name': 'Item', 'quantity': 1, 'price': 100},
    ],
    'merchant_id': 'merch_1',
  },
};

void main() {
  group('OrderEvent.fromWireJson', () {
    test('parses a valid order.created event', () {
      final event = OrderEvent.fromWireJson(_wireEvent());

      expect(event, isNotNull);
      expect(event!.eventId, 'evt_test-1');
      expect(event.type, OrderEventType.created);
      expect(event.data.id, 'ord_1');
      expect(event.data.total, 100);
      expect(event.data.fulfillmentType, FulfillmentType.onSite);
    });

    test('parses order.updated and order.cancelled', () {
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'order.updated'))!.type, OrderEventType.updated);
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'order.cancelled'))!.type, OrderEventType.cancelled);
    });

    test('returns null for an unrecognized event_type', () {
      expect(OrderEvent.fromWireJson(_wireEvent(eventType: 'payment.captured')), isNull);
    });

    test('returns null when data is malformed instead of throwing', () {
      final broken = _wireEvent();
      broken['data'] = {'not': 'a valid order payload'};

      expect(OrderEvent.fromWireJson(broken), isNull);
    });

    test('ignores extra fields present only on the REST payload (id/received_at/created_at wrapper)', () {
      final withExtra = {..._wireEvent(), 'id': 40, 'received_at': '2026-08-21T06:35:15.549Z'};

      final event = OrderEvent.fromWireJson(withExtra);

      expect(event, isNotNull);
      expect(event!.data.id, 'ord_1');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/orders/entities/order_event_test.dart`
Expected: FAIL — `OrderEvent.fromWireJson` doesn't exist yet (compile error).

- [ ] **Step 3: Add `fromWireJson` to `OrderEvent`**

In `lib/features/orders/entities/order_event.dart`, add `import 'dart:convert';`
at the top, then add the factory to the `OrderEvent` class (after its
constructor, before the closing brace):

```dart
@MappableClass()
class OrderEvent with OrderEventMappable {
  const OrderEvent({
    required this.eventId,
    required this.type,
    required this.data,
  });

  final String eventId;
  final OrderEventType type;
  final OrderData data;

  /// Parses one event off either the live WS feed or the REST history
  /// endpoint — both send `{event_type, event_id, data, ...}`, the REST
  /// payload just wraps extra fields (`id`, `received_at`, `created_at`)
  /// around the same three. Returns `null` (never throws) for an
  /// unrecognized `event_type` or a malformed/missing `data`, so a single
  /// bad row never takes down a whole batch of events.
  static OrderEvent? fromWireJson(Map<String, dynamic> json) {
    try {
      final type = OrderEventType.fromWire(json['event_type'] as String);
      if (type == null) return null;
      return OrderEvent(
        eventId: json['event_id'] as String,
        type: type,
        data: OrderData.fromJson(jsonEncode(json['data'])),
      );
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/orders/entities/order_event_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/orders/entities/order_event.dart test/features/orders/entities/order_event_test.dart
git commit -m "feat(kiosk): extract shared OrderEvent.fromWireJson parser"
```

---

## Task 2: Use the shared parser in the WS repository

**Files:**
- Modify: `lib/features/orders/repositories/orders_live_feed_repository.dart`

Delegates the WS repo's inline parsing to `OrderEvent.fromWireJson`, so
behavior can't drift between the WS and REST paths. No test file — this repo
has no existing test harness (it opens a real `WebSocketChannel`); covered by
`flutter analyze` + the Task 1 unit tests it now depends on, plus manual
verification in Task 9.

- [ ] **Step 1: Replace `_parse`'s inline logic**

In `lib/features/orders/repositories/orders_live_feed_repository.dart`,
replace the `_parse` method body:

```dart
  OrderEvent? _parse(Object? raw) {
    if (raw is! String) {
      debugPrint('[OrdersFeed] dropped non-string WS message: $raw');
      return null;
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('[OrdersFeed] failed to decode WS message: $raw\nerror: $e\n$st');
      return null;
    }
    final event = OrderEvent.fromWireJson(json);
    if (event == null) {
      debugPrint('[OrdersFeed] dropped unparseable/unrecognized WS message: $raw');
      return null;
    }
    debugPrint('RECEIVED LIVE DATA ${jsonEncode(json['data'])}');
    return event;
  }
```

This replaces the previous version (which inlined the `OrderEventType.fromWire`
check and `OrderData.fromJson` call inside one big `try`/`catch`). The
`_parse` method's signature, the class it lives in, and every other method
in the file are unchanged.

- [ ] **Step 2: Verify it compiles and analyzes clean**

Run: `dart analyze lib/features/orders/repositories/orders_live_feed_repository.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/orders/repositories/orders_live_feed_repository.dart
git commit -m "refactor(kiosk): reuse shared parser in the live orders WS feed"
```

---

## Task 3: REST client for the orders-events host

**Files:**
- Modify: `lib/data/backend_api/api_clients.dart`

- [ ] **Step 1: Add the new client provider**

In `lib/data/backend_api/api_clients.dart`, add after `cartivoApiClientProvider`:

```dart
/// Client for the webhook-receiver's order-history REST endpoint
/// (`/webhooks/events`) — same host as the live orders WS feed
/// ([AppEnv.ordersLiveFeedWsUrl]), configured separately via
/// [AppEnv.ordersEventsApiBaseUrl] since it's a plain REST call rather than
/// a socket URL. Unauthenticated, like [cartivoApiClientProvider].
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final options = (baseUrl: env.ordersEventsApiBaseUrl, interceptors: <Interceptor>[]);
  final client = httpClientProvider(options);
  return ref.watch(client);
});
```

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze lib/data/backend_api/api_clients.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/backend_api/api_clients.dart
git commit -m "feat(kiosk): add REST client for the orders-history endpoint"
```

---

## Task 4: `OrdersHistoryApi`

**Files:**
- Create: `lib/data/backend_api/sources/orders_history_api.dart`
- Test: `test/data/backend_api/sources/orders_history_api_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/data/backend_api/sources/orders_history_api_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/data/backend_api/sources/orders_history_api.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.body);

  final String body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _wireEvent(String orderId, String eventType, String updatedAt) => {
  'event_id': 'evt_$orderId-$eventType',
  'event_type': eventType,
  'data': {
    'id': orderId,
    'customer_id': 'guest_1',
    'customer_name': null,
    'customer_email': null,
    'status': 'pending',
    'total': 100,
    'currency': 'PHP',
    'district_id': 'dist_1',
    'district_name': 'District One',
    'fulfillment_type': 'on_site',
    'facility_id': 'fac_1',
    'facility_name': 'Table 1',
    'created_at': updatedAt,
    'updated_at': updatedAt,
    'items': const <dynamic>[],
    'merchant_id': 'merch_1',
  },
};

void main() {
  group('OrdersHistoryApi.fetchEvents', () {
    late _FakeHttpClientAdapter adapter;
    late Dio dio;

    setUp(() {
      adapter = _FakeHttpClientAdapter(
        jsonEncode({
          'merchant_id': 'merch_1',
          'events': [
            _wireEvent('ord_1', 'order.created', '2026-08-21T06:35:14.918Z'),
            _wireEvent('ord_2', 'payment.captured', '2026-08-21T06:36:00.000Z'), // dropped
          ],
        }),
      );
      dio = Dio(BaseOptions(baseUrl: 'https://orders-history.test'))..httpClientAdapter = adapter;
    });

    test('fetches, decodes, and drops unrecognized event types', () async {
      final api = OrdersHistoryApi(dio);

      final events = await api.fetchEvents('merch_1');

      expect(events, hasLength(1));
      expect(events.single.data.id, 'ord_1');
      expect(adapter.lastRequest!.path, '/webhooks/events');
      expect(adapter.lastRequest!.queryParameters['merchant_id'], 'merch_1');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/backend_api/sources/orders_history_api_test.dart`
Expected: FAIL — `package:pos_app/data/backend_api/sources/orders_history_api.dart` doesn't exist.

- [ ] **Step 3: Create `OrdersHistoryApi`**

Create `lib/data/backend_api/sources/orders_history_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/orders/entities/order_event.dart';
import '../api_clients.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return OrdersHistoryApi(httpClient);
});

/// Fetches the full stored event log for a merchant from the
/// webhook-receiver's REST history endpoint. This is what backfills the
/// kiosk's local order history — the WS feed only carries events from the
/// moment it connects onward.
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/backend_api/sources/orders_history_api_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/backend_api/sources/orders_history_api.dart test/data/backend_api/sources/orders_history_api_test.dart
git commit -m "feat(kiosk): add OrdersHistoryApi for /webhooks/events"
```

---

## Task 5: Reduce a batch of events to the latest per order

**Files:**
- Create: `lib/features/orders/use_cases/latest_event_per_order.dart`
- Test: `test/features/orders/use_cases/latest_event_per_order_test.dart`

The history endpoint returns the full per-event log (every `created`/
`updated`/`cancelled` row ever recorded for the merchant), not one row per
order. Before persisting, that needs collapsing to one `OrderEvent` per
`orderId` — whichever has the latest `data.updatedAt`.

- [ ] **Step 1: Write the failing test**

Create `test/features/orders/use_cases/latest_event_per_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/orders/entities/order_event.dart';
import 'package:pos_app/features/orders/use_cases/latest_event_per_order.dart';

OrderEvent _event({required String orderId, required DateTime updatedAt, required OrderEventType type}) {
  return OrderEvent(
    eventId: 'evt_$orderId-${updatedAt.microsecondsSinceEpoch}',
    type: type,
    data: OrderData(
      id: orderId,
      customerId: 'guest_1',
      customerName: null,
      customerEmail: null,
      status: type == OrderEventType.cancelled ? 'cancelled' : 'pending',
      total: 100,
      currency: 'PHP',
      districtId: 'dist_1',
      districtName: 'District One',
      fulfillmentType: FulfillmentType.onSite,
      facilityId: 'fac_1',
      facilityName: 'Table 1',
      createdAt: updatedAt,
      updatedAt: updatedAt,
      items: const [],
      merchantId: 'merch_1',
    ),
  );
}

void main() {
  test('keeps only the latest event per order, across multiple orders', () {
    final created = _event(
      orderId: 'ord_1',
      updatedAt: DateTime.utc(2026, 1, 1, 10),
      type: OrderEventType.created,
    );
    final updated = _event(
      orderId: 'ord_1',
      updatedAt: DateTime.utc(2026, 1, 1, 11),
      type: OrderEventType.updated,
    );
    final otherOrder = _event(
      orderId: 'ord_2',
      updatedAt: DateTime.utc(2026, 1, 1, 9),
      type: OrderEventType.created,
    );

    final result = latestEventPerOrder([created, updated, otherOrder]);

    expect(result, hasLength(2));
    expect(result.firstWhere((e) => e.data.id == 'ord_1').type, OrderEventType.updated);
    expect(result.firstWhere((e) => e.data.id == 'ord_2').type, OrderEventType.created);
  });

  test('returns an empty list for an empty input', () {
    expect(latestEventPerOrder(const []), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/orders/use_cases/latest_event_per_order_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement it**

Create `lib/features/orders/use_cases/latest_event_per_order.dart`:

```dart
import '../entities/order_event.dart';

/// Collapses a batch of events (as returned by the REST history endpoint —
/// the full per-event log, not one row per order) down to a single
/// [OrderEvent] per `orderId`: whichever has the latest [OrderData.updatedAt].
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

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/orders/use_cases/latest_event_per_order_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/orders/use_cases/latest_event_per_order.dart test/features/orders/use_cases/latest_event_per_order_test.dart
git commit -m "feat(kiosk): add latestEventPerOrder reduction for history backfill"
```

---

## Task 6: `saveIfNewer` on the local order-events repository

**Files:**
- Create: `lib/features/orders/use_cases/should_replace_stored_order.dart`
- Modify: `lib/core/database/daos/order_events_dao.dart`
- Modify: `lib/features/orders/repositories/order_events_local_repository.dart`
- Test: `test/features/orders/use_cases/should_replace_stored_order_test.dart`

This is the guard that stops a REST backfill from overwriting an order the
live socket already updated more recently. The existing `save()` (used by
the live socket) is untouched — it stays unconditional, since live events
are always trusted.

The actual decision ("is the incoming order newer than what's stored?") is
pulled out into a small pure function so it's unit-testable without a real
database. This project has no existing DAO/repository tests, and this
machine has no `sqlite3.dll` reachable outside a Windows app build
(`build/windows/.../Debug|Release/`, produced only after `flutter run`/`build`
— not present for a plain `flutter test` run, and there's no
`flutter_test_config.dart` overriding `sqlite3.open` to point at it). A
`NativeDatabase.memory()`-backed test would fail here for that reason, not a
logic bug — so the DB-touching wiring itself is covered by `dart analyze`
plus the manual overwrite-race check in Task 9, Step 3 (item 4), matching how
`orders_feed_notifier.dart` and `orders_live_feed_repository.dart` are
already handled in this plan.

- [ ] **Step 1: Write the failing test**

Create `test/features/orders/use_cases/should_replace_stored_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/orders/entities/order_event.dart';
import 'package:pos_app/features/orders/use_cases/should_replace_stored_order.dart';

OrderData _orderData({required DateTime updatedAt}) {
  return OrderData(
    id: 'ord_1',
    customerId: 'guest_1',
    customerName: null,
    customerEmail: null,
    status: 'pending',
    total: 100,
    currency: 'PHP',
    districtId: 'dist_1',
    districtName: 'District One',
    fulfillmentType: FulfillmentType.onSite,
    facilityId: 'fac_1',
    facilityName: 'Table 1',
    createdAt: updatedAt,
    updatedAt: updatedAt,
    items: const [],
    merchantId: 'merch_1',
  );
}

void main() {
  group('shouldReplaceStoredOrder', () {
    test('replaces when there is no existing row', () {
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: null, incoming: incoming), isTrue);
    });

    test('replaces when the incoming order is newer', () {
      final existing = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 12));

      expect(shouldReplaceStoredOrder(existing: existing, incoming: incoming), isTrue);
    });

    test('replaces when the incoming order has the same updatedAt', () {
      final same = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: same, incoming: same), isTrue);
    });

    test('does not replace when the incoming order is older', () {
      final existing = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 12));
      final incoming = _orderData(updatedAt: DateTime.utc(2026, 1, 1, 10));

      expect(shouldReplaceStoredOrder(existing: existing, incoming: incoming), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/orders/use_cases/should_replace_stored_order_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement the pure decision function**

Create `lib/features/orders/use_cases/should_replace_stored_order.dart`:

```dart
import '../entities/order_event.dart';

/// Whether a REST-sourced [incoming] order should overwrite [existing] (the
/// currently stored order state for the same `orderId`, or `null` if none is
/// stored yet). `null` always replaces; otherwise only when [incoming] isn't
/// older than [existing] — ties go to [incoming] since re-writing identical
/// data is harmless.
bool shouldReplaceStoredOrder({required OrderData? existing, required OrderData incoming}) {
  if (existing == null) return true;
  return !incoming.updatedAt.isBefore(existing.updatedAt);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/orders/use_cases/should_replace_stored_order_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Add `getOrder` to the DAO**

In `lib/core/database/daos/order_events_dao.dart`, add this method inside
`OrderEventsDao` (after `upsertOrder`, before `watchPendingCount`):

```dart
  /// The currently stored row for [orderId] within [kioskId], if any — used
  /// to decide whether a REST-sourced event is newer than what's on disk.
  Future<OrderEventsTableData?> getOrder(String orderId, String kioskId) {
    return (select(orderEventsTable)
          ..where((t) => t.orderId.equals(orderId) & t.kioskId.equals(kioskId)))
        .getSingleOrNull();
  }
```

- [ ] **Step 6: Add `saveIfNewer` to the repository**

In `lib/features/orders/repositories/order_events_local_repository.dart`,
add the import:

```dart
import '../use_cases/should_replace_stored_order.dart';
```

Add to the abstract class (after `save`):

```dart
  /// Like [save], but only overwrites the stored row if [event] isn't older
  /// than what's already there (see [shouldReplaceStoredOrder]) — or there's
  /// no stored row yet. Used for REST-sourced history, so a backfill can
  /// never clobber a more recent update the live socket already wrote.
  Future<void> saveIfNewer(OrderEvent event, {required String kioskId});
```

And to `OrderEventsLocalRepositoryImpl` (after the existing `save` override):

```dart
  @override
  Future<void> saveIfNewer(OrderEvent event, {required String kioskId}) async {
    final existingRow = await _dao.getOrder(event.data.id, kioskId);
    final existing = existingRow == null ? null : OrderData.fromJson(existingRow.payload);
    if (!shouldReplaceStoredOrder(existing: existing, incoming: event.data)) return;
    await save(event, kioskId: kioskId);
  }
```

- [ ] **Step 7: Verify it compiles**

Run: `dart analyze lib/core/database/daos/order_events_dao.dart lib/features/orders/repositories/order_events_local_repository.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/orders/use_cases/should_replace_stored_order.dart lib/core/database/daos/order_events_dao.dart lib/features/orders/repositories/order_events_local_repository.dart test/features/orders/use_cases/should_replace_stored_order_test.dart
git commit -m "feat(kiosk): add write-if-newer save for REST-sourced order history"
```

---

## Task 7: Wire the backfill into `OrdersFeedNotifier`

**Files:**
- Modify: `lib/features/orders/state/orders_feed_notifier.dart`

No new test file — this notifier has no existing test harness (real
WebSocket + Riverpod `AsyncNotifier` lifecycle), consistent with the rest of
the file today. Covered by `flutter analyze` here and manual verification in
Task 9.

- [ ] **Step 1: Add imports**

In `lib/features/orders/state/orders_feed_notifier.dart`, add these two
imports alongside the existing ones:

```dart
import '../../../data/backend_api/sources/orders_history_api.dart';
import '../use_cases/latest_event_per_order.dart';
```

- [ ] **Step 2: Add `_syncHistory` and call it from `_connect`**

Replace the existing `_connect` method:

```dart
  Future<void> _connect() async {
    _retryTimer?.cancel();
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      _kioskId = terminal.kioskId;
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(terminal.kioskId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(_onEvent, onError: _onDrop, onDone: _onDrop);
      _setConnection(OrdersFeedConnection.connected, kioskId: terminal.kioskId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect();
    }
  }
```

with:

```dart
  Future<void> _connect() async {
    _retryTimer?.cancel();
    try {
      final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
      _kioskId = terminal.kioskId;
      await _syncHistory(terminal.kioskId);
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(terminal.kioskId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(_onEvent, onError: _onDrop, onDone: _onDrop);
      _setConnection(OrdersFeedConnection.connected, kioskId: terminal.kioskId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect();
    }
  }

  /// Backfills local order history for [kioskId] from the REST endpoint,
  /// merging with write-if-newer semantics so it can never overwrite an
  /// order the live socket has already updated more recently. Runs before
  /// the socket opens in [_connect] (covering login and kiosk-ID changes
  /// for free, since both already rebuild this notifier); also callable
  /// standalone via [refreshHistory]. Best-effort: a failure here doesn't
  /// stop the socket from connecting, and doesn't surface an error to the
  /// UI — the screen keeps showing whatever's already persisted.
  Future<void> _syncHistory(String kioskId) async {
    try {
      final events = await ref.read(ordersHistoryApiProvider).fetchEvents(kioskId);
      final latest = latestEventPerOrder(events);
      final repository = ref.read(orderEventsLocalRepositoryProvider);
      for (final event in latest) {
        await repository.saveIfNewer(event, kioskId: kioskId);
      }
    } catch (e, st) {
      debugPrint('[OrdersFeed] history backfill failed: $e\n$st');
    }
  }

  /// Re-fetches order history from the REST endpoint and merges it into
  /// local storage, without touching the live socket connection. Used by
  /// the Orders screen's on-mount load and pull-to-refresh. No-ops if this
  /// notifier hasn't resolved a kiosk ID yet (not logged in / still
  /// connecting for the first time).
  Future<void> refreshHistory() async {
    final kioskId = _kioskId;
    if (kioskId == null) return;
    await _syncHistory(kioskId);
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `dart analyze lib/features/orders/state/orders_feed_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/orders/state/orders_feed_notifier.dart
git commit -m "feat(kiosk): backfill order history before connecting the live feed"
```

---

## Task 8: Orders screen — auto-refresh on mount + pull-to-refresh

**Files:**
- Modify: `lib/features/orders/view/orders_screen.dart`

- [ ] **Step 1: Trigger a refresh on mount**

In `lib/features/orders/view/orders_screen.dart`, inside `OrdersScreen.build`,
add a `useEffect` right after the existing `useState` line:

```dart
    final events = ref.watch(persistedOrdersProvider).value ?? const [];
    final selected = useState(OrdersFilter.all);

    useEffect(() {
      unawaited(ref.read(ordersFeedNotifierProvider.notifier).refreshHistory());
      return null;
    }, const []);
```

Add the notifier import alongside the existing ones:

```dart
import '../state/orders_feed_notifier.dart';
```

- [ ] **Step 2: Wrap the board in a `RefreshIndicator`**

Replace the `Expanded` block in `OrdersScreen.build`:

```dart
          Expanded(
            child:
                events.isEmpty
                    ? const _EmptyBody()
                    : _OrdersBody(
                      events: events.toIList(),
                      selected: selected.value,
                      onSelect: (f) => selected.value = f,
                    ),
          ),
```

with:

```dart
          Expanded(
            child:
                events.isEmpty
                    ? const _EmptyBody()
                    : RefreshIndicator(
                      onRefresh: () => ref.read(ordersFeedNotifierProvider.notifier).refreshHistory(),
                      child: _OrdersBody(
                        events: events.toIList(),
                        selected: selected.value,
                        onSelect: (f) => selected.value = f,
                      ),
                    ),
          ),
```

`RefreshIndicator` picks up `ScrollNotification`s bubbling from any
`Scrollable` descendant — here, the `AnimatedList` inside each kanban
column — so one indicator wrapping `_OrdersBody` covers every column
without changes to `order_kanban_board.dart`. The empty state
(`_EmptyBody`) isn't wrapped: there's nothing to pull against with zero
orders, and the screen already refreshes automatically on mount.

- [ ] **Step 3: Verify it compiles**

Run: `dart analyze lib/features/orders/view/orders_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/orders/view/orders_screen.dart
git commit -m "feat(kiosk): refresh order history on Orders screen mount + pull-to-refresh"
```

---

## Task 9: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests pass, including the 4 new test files from Tasks 1, 4, 5, 6.

- [ ] **Step 2: Run static analysis on the whole project**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 3: Manual smoke test in the running app**

Run: `flutter run -d windows`

1. Log in with a cashier PIN → open the Orders screen → orders that exist
   in the REST history for this kiosk's `merchant_id` appear (not just ones
   received live since launch).
2. Open Settings → POS Terminal Details → change the Kiosk ID → Save →
   confirm the Orders screen now shows the *new* kiosk's history and the
   old kiosk's orders are gone.
3. On the Orders screen, swipe down over the kanban board → confirm a
   refresh indicator appears and completes without a visible WS
   "reconnecting" flash (check the `[OrdersFeed]` debug logs in the run
   console — no `disconnected`/`connecting` transition should log during
   the swipe).
4. While the socket is connected, use the kanban board's status controls to
   move an order to a new status, then immediately swipe-to-refresh —
   confirm the status change is not reverted by the backfill.

- [ ] **Step 4: Final commit (if smoke testing turned up fixes)**

```bash
git add -A
git commit -m "fix(kiosk): address issues found during orders history backfill smoke test"
```

Skip this step if no fixes were needed.
