# Order status update / cancel actions — design

## Context

The Orders kanban board (`kiosk/lib/features/orders/`) currently displays orders as read-only cards, grouped into columns by status (`order_kanban_board.dart`). Status changes only ever arrive *into* the app from the webhook-receiver's live WebSocket feed (`orders_live_feed_repository.dart` → `orders_feed_notifier.dart`) — there is currently no way for kiosk staff to change an order's status or cancel it from this screen.

Two REST endpoints exist for this on the same webhook-receiver service the socket connects to:

- `PATCH /api/orders/:id/status` — body `{"status": "<status>"}`
- `POST /api/orders/:id/cancel` — empty body

Neither requires auth. Both live on a different host than the main backend (`backendApiBaseUrl`, port 3000, `/api/v1/...`) — the webhook-receiver, currently reachable in dev at `192.168.1.18:3100`.

Because the board is entirely event-sourced from the socket (`OrdersFeedNotifier._onEvent` is the only writer of `OrdersFeedState.events`), these new calls don't need to update local Riverpod state themselves — firing the request is enough; the resulting `order.updated`/`order.cancelled` event will arrive over the socket and the existing `AnimatedList`-based kanban board (`order_kanban_board.dart`) will animate the card into its new column on its own.

## Goals

- Let staff change an order's status, or cancel it, directly from its card on the kanban board.
- Reuse the existing socket-driven refresh — no manual state patching after a successful call.
- Match the reference layout: a tappable status pill (dropdown) in the card header, and a separate outlined "Cancel Order" button.
- Keep the two REST endpoints configurable, not hardcoded, following the same pattern already used for the WS URL.

## Non-goals

- No optimistic UI update of the card's status ahead of the socket echo — the existing live-feed connection is treated as the single source of truth for order state, exactly as it is today for staff-independent updates (e.g. from a POS terminal or the backend itself).
- No changes to `fulfilled`/`cancelled`/`unknown` cards — they stay fully read-only, as today (`isCancelled` already dims/disables taps on cancelled cards).
- No retry/offline queueing for these calls. A failed request just shows an error and lets staff tap again.
- No change to the existing order-details dialog (`order_items_dialog.dart`) — actions live on the card only, per the "directly on the card" decision.

## Design

### 1. Config

`CARTIVO_AUTH_API_BASE_URL` already exists (unused) in the local `.env` file. It becomes the base URL for these two endpoints:

- Add `cartivoAuthApiBaseUrl` as an `@EnviedField()` on `AppEnv` (`app_env.dart`), `Env` (`env.dart`), and `EnvDev` (`env_dev.dart`) — mirrors how `ordersLiveFeedWsUrl` is already declared.
- Add `CARTIVO_AUTH_API_BASE_URL=` to `.env.sample`.
- Update the local `.env` value to `http://192.168.1.18:3100` (currently `http://localhost:3100`).
- Add `cartivoApiClientProvider` to `api_clients.dart`: a `Dio` client via `httpClientProvider`, `baseUrl: env.cartivoAuthApiBaseUrl`, no interceptors (unauthenticated) — same shape as `openApiClientProvider` but a different base URL.

### 2. Data layer

New `lib/data/backend_api/sources/orders_api.dart`, following the existing API-source pattern (see `sales_orders_api.dart`):

```dart
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final httpClient = ref.watch(cartivoApiClientProvider);
  return OrdersApi(httpClient);
});

class OrdersApi {
  const OrdersApi(this._httpClient);
  final Dio _httpClient;

  Future<void> updateStatus(String orderId, String status) async {
    await _httpClient.patch<dynamic>('/api/orders/$orderId/status', data: {'status': status});
  }

  Future<void> cancel(String orderId) async {
    await _httpClient.post<dynamic>('/api/orders/$orderId/cancel');
  }
}
```

No response DTOs — callers don't consume the response body; success/failure is a plain `Future<void>` that either completes or throws (`DioException` on non-2xx).

Status values sent match the raw lowercase strings already used elsewhere (`order_status.dart`'s `classifyOrderStatus` switch: `pending`, `preparing`, `ready`, `fulfilled`).

### 3. Card UI (`order_card.dart`)

`OrderCard` changes from `StatelessWidget` to `HookConsumerWidget` (matches the rest of the app's Riverpod/hooks convention) so it can call `ref.read(ordersApiProvider)` and hold a local `useState<bool>` for `isSubmitting`.

Controls only render for **actionable** statuses — `pending`, `preparing`, `ready`. `fulfilled`, `cancelled`, and `unknown` cards keep their current fully-read-only rendering (existing `_StatusIndicator`/`_Pill`, no dropdown, no cancel button).

**Status dropdown** (replaces the current status pill/`_PreparingDots` row for actionable cards):
- Same pill visual as today (color per status), plus a small chevron-down icon.
- Wrapped in a `PopupMenuButton<String>` listing all four actionable+terminal-forward statuses a staff member can set: Pending, Preparing, Ready, Fulfilled (not Cancelled — that's the dedicated button below). The current status is shown checked/disabled in the menu.
- Selecting a different status calls `ordersApi.updateStatus(order.id, status)`.

**Cancel button**:
- New row below the price row, only for actionable-status cards: an outlined button, danger-colored border/text (`ColorSet.danger`, matching `POSColors`/`POSRadius` conventions — not the sample screenshot's exact styling, which is from an unrelated app), label "Cancel Order".
- Tapping opens a small confirmation dialog ("Cancel this order?" / Keep / Cancel Order) before calling `ordersApi.cancel(order.id)`.

**In-flight / error handling** (shared by both controls):
- While a request is in flight, both controls disable and the active one shows a small inline `CircularProgressIndicator` in place of its icon/chevron.
- On failure, `ScaffoldMessenger.of(context).showSnackBar(...)` with a short error message (pattern from `product_dialogs.dart`), then re-enable — no automatic retry.
- On success, nothing further happens locally — the socket delivers the update and the kanban board's existing `AnimatedList` diffing (`order_kanban_board.dart`) animates the card into its new column, or removes it from view if it moved to a collapsed empty terminal column.

### 4. Testing

- `dart analyze` across `kiosk/lib` after each file change.
- Manual verification via `flutter run -d windows`: change a pending order to preparing/ready/fulfilled and confirm the card animates into the right column once the socket echoes it back; trigger a cancel and confirm the confirmation dialog, then the resulting removal/move; verify the SnackBar path by temporarily pointing `CARTIVO_AUTH_API_BASE_URL` at an unreachable host.
