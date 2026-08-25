# Orders History Backfill (Mobile) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backfill the mobile app's local order history from the webhook-receiver's `GET /webhooks/events` REST endpoint — on login, on store-ID change (settings save), on Orders-screen mount, and via pull-to-refresh — without letting stale REST data overwrite fresher data the live WebSocket feed has already written.

**Architecture:** Introduce `dio` and a `lib/data/backend_api/` folder (mobile has no REST client today). A new `OrdersHistoryApi` fetches and parses the REST event log, reusing the WS feed's JSON parsing extracted into a shared `OrderEvent.fromWireJson`. A new `saveIfNewer` on the local order-events repository only overwrites a stored order if the incoming payload isn't older. `OrdersFeedNotifier` runs the backfill before opening its WebSocket session (covering login + store-ID change for free, since both already trigger `_connect()` via `build()`'s `ref.watch(storeInfoProvider.future)`) and exposes a `refreshHistory()` for the Orders screen to call on mount and via `RefreshIndicator`.

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), `flutter_hooks`, Dio, Drift (local SQLite).

**Reference spec:** `docs/superpowers/specs/2026-08-24-orders-history-backfill-mobile-design.md`

---

## Task 1: Dependency + env var

**Files:**
- Modify: `pubspec.yaml`
- Modify: `.env.sample`
- Modify: `.env`
- Modify: `lib/config/environment/app_env.dart`
- Modify: `lib/config/environment/env.dart`

- [x] **Step 1: Add the `dio` dependency**

In `pubspec.yaml`, add a new `# Network` section right after the existing
`# Realtime` block (before `# Environment config`):

```yaml
  # Realtime
  web_socket_channel: ^3.0.3
  connectivity_plus: ^6.1.0
  flutter_local_notifications: ^22.3.0

  # Network
  dio: ^5.9.0

  # Environment config
  envied: ^1.3.2
```

- [x] **Step 2: Run `pub get`**

Run: `flutter pub get`
Expected: resolves cleanly, `pubspec.lock` picks up `dio: 5.9.0` (or latest
compatible 5.9.x).

- [x] **Step 3: Add the env var to `.env.sample` and `.env`**

In `.env.sample`, add after the existing `ORDERS_LIVE_FEED_WS_URL` line:

```
ORDERS_LIVE_FEED_WS_URL=https://your-webhook-receiver.example.com
ORDERS_EVENTS_API_BASE_URL=https://your-webhook-receiver.example.com
```

In `.env` (local, untracked), add after the existing
`ORDERS_LIVE_FEED_WS_URL` line:

```
ORDERS_LIVE_FEED_WS_URL=https://dposocket.onrender.com
ORDERS_EVENTS_API_BASE_URL=https://dposocket.onrender.com
```

- [x] **Step 4: Add the field to `AppEnv`**

In `lib/config/environment/app_env.dart`, replace the file with:

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class AppEnv {
  String get ordersLiveFeedWsUrl;
  String get ordersEventsApiBaseUrl;
}

/// Overridden in main() with the concrete env (Env, backed by .env via
/// envied) — mirrors the kiosk app's `appEnvProvider`.
final appEnvProvider = Provider<AppEnv>((_) => throw UnimplementedError('appEnvProvider not overridden'));
```

- [x] **Step 5: Add the field to `Env`**

In `lib/config/environment/env.dart`, replace the file with:

```dart
import 'package:envied/envied.dart';

import 'app_env.dart';

part 'env.g.dart';

@Envied(path: '.env', useConstantCase: true)
final class Env implements AppEnv {
  Env();

  @EnviedField()
  @override
  final String ordersLiveFeedWsUrl = _Env.ordersLiveFeedWsUrl;

  @EnviedField()
  @override
  final String ordersEventsApiBaseUrl = _Env.ordersEventsApiBaseUrl;
}
```

- [x] **Step 6: Regenerate `env.g.dart`**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds, `lib/config/environment/env.g.dart` now includes
`ordersEventsApiBaseUrl`.

- [x] **Step 7: Verify it compiles**

Run: `dart analyze lib/config/environment`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock .env.sample lib/config/environment/app_env.dart lib/config/environment/env.dart lib/config/environment/env.g.dart
git commit -m "feat: add dio dependency and orders-events API base URL env var"
```

`.env` is untracked (local secrets/config) — nothing to stage there.

---

## Task 2: Shared WS/REST event parser

**Files:**
- Modify: `lib/features/live_orders/entities/order_event.dart`
- Test: `test/features/live_orders/entities/order_event_test.dart`

The WS repository currently parses each message's JSON inline in
`OrdersLiveFeedRepositoryImpl._parse`. Both the WS feed and the new REST
fetch need identical "is this a valid order event" logic, so it moves onto
`OrderEvent` itself as a static factory.

- [x] **Step 1: Write the failing test**

Create `test/features/live_orders/entities/order_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live_orders/entities/order_event.dart';

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

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/live_orders/entities/order_event_test.dart`
Expected: FAIL — `OrderEvent.fromWireJson` doesn't exist yet (compile error).

- [x] **Step 3: Add `fromWireJson` to `OrderEvent`**

In `lib/features/live_orders/entities/order_event.dart`, replace the final
`OrderEvent` class (lines 166-176):

```dart
class OrderEvent {
  const OrderEvent({
    required this.eventId,
    required this.type,
    required this.data,
  });

  final String eventId;
  final OrderEventType type;
  final OrderData data;
}
```

with:

```dart
class OrderEvent {
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
        data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/live_orders/entities/order_event_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/live_orders/entities/order_event.dart test/features/live_orders/entities/order_event_test.dart
git commit -m "feat: extract shared OrderEvent.fromWireJson parser"
```

---

## Task 3: Use the shared parser in the WS repository

**Files:**
- Modify: `lib/features/live_orders/repositories/orders_live_feed_repository.dart`

Delegates the WS repo's inline parsing to `OrderEvent.fromWireJson`, so
behavior can't drift between the WS and REST paths. No test file — this repo
has no existing test harness (it opens a real `WebSocketChannel`); covered by
`dart analyze` + the Task 2 unit tests it now depends on, plus manual
verification in Task 9.

- [x] **Step 1: Replace `_parse`'s inline logic**

In `lib/features/live_orders/repositories/orders_live_feed_repository.dart`,
replace the `_parse` method (lines 77-98):

```dart
  OrderEvent? _parse(Object? raw) {
    if (raw is! String) {
      debugPrint('[OrdersFeed] dropped non-string WS message: $raw');
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final type = OrderEventType.fromWire(json['event_type'] as String);
      if (type == null) {
        debugPrint('[OrdersFeed] dropped unrecognized event_type: ${json['event_type']}');
        return null;
      }
      return OrderEvent(
        eventId: json['event_id'] as String,
        type: type,
        data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } catch (e, st) {
      debugPrint('[OrdersFeed] failed to parse WS message: $raw\nerror: $e\n$st');
      return null;
    }
  }
```

with:

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
    }
    return event;
  }
```

This replaces the previous version (which inlined the
`OrderEventType.fromWire` check and `OrderData.fromJson` call inside one big
`try`/`catch`) with a delegation to the shared parser. The method's
signature, the class it lives in, and every other method in the file are
unchanged.

- [x] **Step 2: Verify it compiles and analyzes clean**

Run: `dart analyze lib/features/live_orders/repositories/orders_live_feed_repository.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/live_orders/repositories/orders_live_feed_repository.dart
git commit -m "refactor: reuse shared parser in the live orders WS feed"
```

---

## Task 4: REST client for the orders-events host

**Files:**
- Create: `lib/data/backend_api/api_clients.dart`

This is mobile's first REST client — no `sources/`, `schemas/`, or
`mappers/` subfolders exist yet; only `api_clients.dart` is needed for this
change (per the design spec, a shared `httpClientProvider` abstraction isn't
introduced until a second REST client shows up).

- [x] **Step 1: Create the directory and file**

Create `lib/data/backend_api/api_clients.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';

/// Client for the webhook-receiver's order-history REST endpoint
/// (`/webhooks/events`) — same host as the live orders WS feed
/// ([AppEnv.ordersLiveFeedWsUrl]), configured separately via
/// [AppEnv.ordersEventsApiBaseUrl] since it's a plain REST call rather than
/// a socket URL. Unauthenticated — this is the only REST client mobile has,
/// so no shared `httpClientProvider` abstraction is introduced; if a second
/// REST client shows up later, factor the shared bits out then.
final ordersEventsApiClientProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  return Dio(BaseOptions(baseUrl: env.ordersEventsApiBaseUrl));
});
```

- [x] **Step 2: Verify it compiles**

Run: `dart analyze lib/data/backend_api/api_clients.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/backend_api/api_clients.dart
git commit -m "feat: add REST client for the orders-history endpoint"
```

---

## Task 5: `OrdersHistoryApi`

**Files:**
- Create: `lib/data/backend_api/sources/orders_history_api.dart`
- Test: `test/data/backend_api/sources/orders_history_api_test.dart`

- [x] **Step 1: Write the failing test**

Create `test/data/backend_api/sources/orders_history_api_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/backend_api/sources/orders_history_api.dart';

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

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/backend_api/sources/orders_history_api_test.dart`
Expected: FAIL — `package:mobile/data/backend_api/sources/orders_history_api.dart` doesn't exist.

- [x] **Step 3: Create `OrdersHistoryApi`**

Create `lib/data/backend_api/sources/orders_history_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/live_orders/entities/order_event.dart';
import '../api_clients.dart';

final ordersHistoryApiProvider = Provider<OrdersHistoryApi>((ref) {
  final httpClient = ref.watch(ordersEventsApiClientProvider);
  return OrdersHistoryApi(httpClient);
});

/// Fetches the full stored event log for a merchant from the
/// webhook-receiver's REST history endpoint. This is what backfills the
/// app's local order history — the WS feed only carries events from the
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

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/backend_api/sources/orders_history_api_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/backend_api/sources/orders_history_api.dart test/data/backend_api/sources/orders_history_api_test.dart
git commit -m "feat: add OrdersHistoryApi for /webhooks/events"
```

---

## Task 6: Reduce a batch of events to the latest per order

**Files:**
- Create: `lib/features/live_orders/use_cases/latest_event_per_order.dart`
- Test: `test/features/live_orders/use_cases/latest_event_per_order_test.dart`

The history endpoint returns the full per-event log (every `created`/
`updated`/`cancelled` row ever recorded for the merchant), not one row per
order. Before persisting, that needs collapsing to one `OrderEvent` per
`orderId` — whichever has the latest `data.updatedAt`.

- [x] **Step 1: Write the failing test**

Create `test/features/live_orders/use_cases/latest_event_per_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live_orders/entities/order_event.dart';
import 'package:mobile/features/live_orders/use_cases/latest_event_per_order.dart';

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

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/live_orders/use_cases/latest_event_per_order_test.dart`
Expected: FAIL — file doesn't exist.

- [x] **Step 3: Implement it**

Create `lib/features/live_orders/use_cases/latest_event_per_order.dart`:

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

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/live_orders/use_cases/latest_event_per_order_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/live_orders/use_cases/latest_event_per_order.dart test/features/live_orders/use_cases/latest_event_per_order_test.dart
git commit -m "feat: add latestEventPerOrder reduction for history backfill"
```

---

## Task 7: `saveIfNewer` on the local order-events repository

**Files:**
- Create: `lib/features/live_orders/use_cases/should_replace_stored_order.dart`
- Modify: `lib/core/database/daos/order_events_dao.dart`
- Modify: `lib/features/live_orders/repositories/order_events_local_repository.dart`
- Test: `test/features/live_orders/use_cases/should_replace_stored_order_test.dart`

This is the guard that stops a REST backfill from overwriting an order the
live socket already updated more recently. The existing `save()` (used by
the live socket) is untouched — it stays unconditional, since live events
are always trusted.

- [x] **Step 1: Write the failing test**

Create `test/features/live_orders/use_cases/should_replace_stored_order_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live_orders/entities/order_event.dart';
import 'package:mobile/features/live_orders/use_cases/should_replace_stored_order.dart';

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

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/live_orders/use_cases/should_replace_stored_order_test.dart`
Expected: FAIL — file doesn't exist.

- [x] **Step 3: Implement the pure decision function**

Create `lib/features/live_orders/use_cases/should_replace_stored_order.dart`:

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

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/live_orders/use_cases/should_replace_stored_order_test.dart`
Expected: PASS (4 tests)

- [x] **Step 5: Add `getOrder` to the DAO**

In `lib/core/database/daos/order_events_dao.dart`, add this method inside
`OrderEventsDao` (after `upsertOrder`, before `watchPendingCount`):

```dart
  /// The currently stored row for [orderId] within [storeId], if any — used
  /// to decide whether a REST-sourced event is newer than what's on disk.
  Future<OrderEventsTableData?> getOrder(String orderId, String storeId) {
    return (select(orderEventsTable)
          ..where((t) => t.orderId.equals(orderId) & t.storeId.equals(storeId)))
        .getSingleOrNull();
  }
```

- [x] **Step 6: Add `saveIfNewer` to the repository**

In `lib/features/live_orders/repositories/order_events_local_repository.dart`,
add the import alongside the existing ones:

```dart
import '../use_cases/should_replace_stored_order.dart';
```

Add to the abstract class (after `save`):

```dart
  /// Like [save], but only overwrites the stored row if [event] isn't older
  /// than what's already there (see [shouldReplaceStoredOrder]) — or there's
  /// no stored row yet. Used for REST-sourced history, so a backfill can
  /// never clobber a more recent update the live socket already wrote.
  Future<Result<void, AppError>> saveIfNewer(OrderEvent event, {required String storeId});
```

And to `OrderEventsLocalRepositoryImpl` (after the existing `save`
override):

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

- [x] **Step 7: Verify it compiles**

Run: `dart analyze lib/core/database/daos/order_events_dao.dart lib/features/live_orders/repositories/order_events_local_repository.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/live_orders/use_cases/should_replace_stored_order.dart lib/core/database/daos/order_events_dao.dart lib/features/live_orders/repositories/order_events_local_repository.dart test/features/live_orders/use_cases/should_replace_stored_order_test.dart
git commit -m "feat: add write-if-newer save for REST-sourced order history"
```

---

## Task 8: Wire the backfill into `OrdersFeedNotifier`

**Files:**
- Modify: `lib/features/live_orders/state/orders_feed_notifier.dart`

No new test file — this notifier has no existing test harness (real
WebSocket + Riverpod `AsyncNotifier` lifecycle), consistent with the rest of
the file today. Covered by `dart analyze` here and manual verification in
Task 10.

- [x] **Step 1: Add imports**

In `lib/features/live_orders/state/orders_feed_notifier.dart`, add these
imports alongside the existing ones (`flutter/foundation.dart` is needed for
`debugPrint`, which this file doesn't currently import):

```dart
import 'package:flutter/foundation.dart';

import '../../../data/backend_api/sources/orders_history_api.dart';
import '../use_cases/latest_event_per_order.dart';
```

- [x] **Step 2: Add `_syncHistory` and call it from `_connect`**

Replace the existing `_connect` method:

```dart
  Future<void> _connect(String storeId) async {
    _retryTimer?.cancel();
    try {
      _storeId = storeId;
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(storeId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(
        _onEvent,
        onError: _onDrop,
        onDone: _onDrop,
      );
      _setConnection(OrdersFeedConnection.connected, storeId: storeId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect(storeId);
    }
  }
```

with:

```dart
  Future<void> _connect(String storeId) async {
    _retryTimer?.cancel();
    try {
      _storeId = storeId;
      await _syncHistory(storeId);
      final repository = ref.read(ordersLiveFeedRepositoryProvider);
      final session = repository.connect(storeId);
      _session = session;
      await session.ready.timeout(_readyTimeout);

      _connectedAt = DateTime.now();
      _subscription = session.events.listen(
        _onEvent,
        onError: _onDrop,
        onDone: _onDrop,
      );
      _setConnection(OrdersFeedConnection.connected, storeId: storeId);
    } catch (_) {
      unawaited(_session?.close());
      _session = null;
      _setConnection(OrdersFeedConnection.reconnecting);
      _scheduleReconnect(storeId);
    }
  }

  /// Backfills local order history for [storeId] from the REST endpoint,
  /// merging with write-if-newer semantics so it can never overwrite an
  /// order the live socket has already updated more recently. Runs before
  /// the socket opens in [_connect] (covering login and store-ID changes
  /// for free, since both already rebuild this notifier); also callable
  /// standalone via [refreshHistory]. Best-effort: a failure here doesn't
  /// stop the socket from connecting, and doesn't surface an error to the
  /// UI — the screen keeps showing whatever's already persisted.
  Future<void> _syncHistory(String storeId) async {
    try {
      final events = await ref.read(ordersHistoryApiProvider).fetchEvents(storeId);
      final latest = latestEventPerOrder(events);
      final repository = ref.read(orderEventsLocalRepositoryProvider);
      for (final event in latest) {
        await repository.saveIfNewer(event, storeId: storeId);
      }
    } catch (e, st) {
      debugPrint('[OrdersFeed] history backfill failed: $e\n$st');
    }
  }

  /// Re-fetches order history from the REST endpoint and merges it into
  /// local storage, without touching the live socket connection. Used by
  /// the Orders screen's on-mount load and pull-to-refresh. No-ops if this
  /// notifier hasn't resolved a store ID yet (not logged in / still
  /// connecting for the first time).
  Future<void> refreshHistory() async {
    final storeId = _storeId;
    if (storeId == null) return;
    await _syncHistory(storeId);
  }
```

- [x] **Step 3: Verify it compiles**

Run: `dart analyze lib/features/live_orders/state/orders_feed_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/live_orders/state/orders_feed_notifier.dart
git commit -m "feat: backfill order history before connecting the live feed"
```

---

## Task 9: Orders screen — auto-refresh on mount + pull-to-refresh

**Files:**
- Modify: `lib/features/orders/view/orders_screen.dart`

The screen currently is a plain `ConsumerWidget`; it becomes a
`HookConsumerWidget` so it can use `useEffect` for the on-mount refresh.

- [x] **Step 1: Convert to `HookConsumerWidget` and trigger a refresh on mount**

In `lib/features/orders/view/orders_screen.dart`, replace the import block
(lines 1-12):

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../live_orders/entities/order_event.dart';
import '../../live_orders/state/pending_orders_count_provider.dart';
import 'order_status.dart';
```

with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../live_orders/entities/order_event.dart';
import '../../live_orders/state/orders_feed_notifier.dart';
import '../../live_orders/state/pending_orders_count_provider.dart';
import 'order_status.dart';
```

Then replace the class declaration and the start of `build` (lines 19-24):

```dart
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(persistedOrdersProvider);
```

with:

```dart
class OrdersScreen extends HookConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(persistedOrdersProvider);

    useEffect(() {
      unawaited(ref.read(ordersFeedNotifierProvider.notifier).refreshHistory());
      return null;
    }, const []);
```

- [x] **Step 2: Wrap the order list in a `RefreshIndicator`**

Replace the `data:` branch of `ordersAsync.when` (lines 51-67):

```dart
          data: (orders) {
            if (orders.isEmpty) {
              return const EmptyStateWidget(
                title: 'No orders yet',
                subtitle: 'New orders placed through your storefront will show up here in real time.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _OrderCard(
                event: orders[index],
                onTap: () => _showOrderDetail(context, orders[index]),
              ),
            );
          },
```

with:

```dart
          data: (orders) {
            if (orders.isEmpty) {
              return const EmptyStateWidget(
                title: 'No orders yet',
                subtitle: 'New orders placed through your storefront will show up here in real time.',
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(ordersFeedNotifierProvider.notifier).refreshHistory(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _OrderCard(
                  event: orders[index],
                  onTap: () => _showOrderDetail(context, orders[index]),
                ),
              ),
            );
          },
```

The empty state (`EmptyStateWidget`) stays outside the `RefreshIndicator`,
matching the kiosk's equivalent (`_EmptyBody` un-wrapped) — pull-to-refresh
isn't reachable with zero rows either way, and the screen already refreshes
automatically on mount.

- [x] **Step 3: Verify it compiles**

Run: `dart analyze lib/features/orders/view/orders_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/orders/view/orders_screen.dart
git commit -m "feat: refresh order history on Orders screen mount + pull-to-refresh"
```

---

## Task 10: Full verification

**Files:** none (verification only)

- [x] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests pass, including the 4 new test files from Tasks 2, 5, 6, 7.

- [x] **Step 2: Run static analysis on the whole project**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 3: Manual smoke test in the running app**

Run: `flutter run -d windows` (or `-d android`)

1. Log in → open the Orders screen → orders that exist in the REST history
   for this store's `merchant_id` appear (not just ones received live since
   launch).
2. Open Settings → Store Info → change the Store ID → Save → confirm the
   Orders screen now shows the *new* store's history and the old store's
   orders are gone.
3. On the Orders screen, pull down over the list → confirm a refresh
   indicator appears and completes without a visible WS "reconnecting"
   flash (check the `[OrdersFeed]` debug logs in the run console — no
   `disconnected`/`connecting` transition should log during the pull).
4. While the socket is connected and an order updates in real time,
   immediately trigger a pull-to-refresh at the same moment — confirm the
   real-time update is not reverted by the backfill.

- [ ] **Step 4: Final commit (if smoke testing turned up fixes)**

```bash
git add -A
git commit -m "fix: address issues found during orders history backfill smoke test"
```

Skip this step if no fixes were needed.
