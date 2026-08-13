# Replenishment checkout + ordering flow (design)

## Current state

The replenishment feature (`kiosk/lib/features/replenishment/`) currently supports browsing
products (`GET /api/products`) and building a local cart (`ReplenishmentCartNotifier`, in-memory
only, never sent to a backend). `ReplenishmentCartScreen` shows items and a running total but has
no checkout action — the cart is a dead end. This spec adds the missing order-placement and
payment flow against the same external API (`REPLENISHMENT_API_BASE_URL`, via
`replenishmentApiClientProvider`).

## Goals

1. A "Checkout" action on the cart screen that creates an order from the cart contents.
2. A way to pay for orders, done separately from checkout, from a dedicated Orders section.
3. Visibility into orders placed so far, with a badge indicating orders still awaiting payment.

## Non-goals

- No partial payments, refunds, or order cancellation UI.
- No offline queueing — checkout/pay require a live connection to the replenishment API (same
  assumption `ReplenishmentProductsApi` already makes).
- No changes to the POS's own sales/orders system (`lib/features/sales/`) — this is a separate
  external API for a separate "replenishment" vendor flow.

## API contracts (external, `REPLENISHMENT_API_BASE_URL`)

```
POST /api/orders
  body: { customer_id: string, items: [{ product_id: string, quantity: number }] }
  → 200 single order object:
    {
      id: string;                    // "ord_<uuid>"
      customer_id: string;
      customer_name: string | null;
      customer_email: string | null;
      status: string;                // "pending" | "paid" | "cancelled"
      total: number;                 // assumed cents, see "Open assumption" below
      currency: string;
      created_at: string;            // ISO 8601
      updated_at: string;            // ISO 8601
      items: [{ product_id, product_name, quantity, price }];  // price assumed cents
    }

GET /api/orders?customer_id=<id>
  → 200 array of order objects, same shape as above MINUS `items` (omitted entirely)

POST /api/orders/:id/pay
  body: {} | { simulateFailure: true }
  → 200 wrapper object:
    {
      order: <same shape as POST /api/orders response, i.e. WITH items>,
             // status "paid" on success; unchanged if simulateFailure:true
      payment: {
        id: string;                  // "pay_..."
        order_id: string;
        amount: number;
        currency: string;
        status: string;              // e.g. "completed" / "failed"
        created_at: string;
        updated_at: string;
      }
    }
```

`customer_id` is the current logged-in user's id (`Auth.id`, an `int`) converted to a string —
sourced from `loginStateProvider` (`AsyncNotifierProvider<LoginStateNotifier, Auth?>`,
`lib/features/auth/state/login_state_notifier.dart`).

**Open assumption (needs confirmation once the real API is reachable):** `ReplenishmentProductDto`
stores `price` in cents and the entity mapper divides by 100 to get dollars
(`replenishment_product_mappers.dart`). This spec assumes the orders API follows the same
convention for `total` and item `price`, and mirrors that `/100` conversion in the order entity
mapper. If the orders API actually returns already-divided currency values, totals will render at
1/100th of the correct amount and the mapper will need the conversion removed.

## Data layer

**DTOs** — `kiosk/lib/data/backend_api/schemas/`:
- `replenishment_order_dto.dart` — `OrderDto` (`@MappableClass`), fields as in the API contract
  above; `items` is `List<OrderItemDto>?` (nullable — absent on the GET-list response, present on
  create/pay responses).
- `replenishment_order_item_dto.dart` — `OrderItemDto` (productId/productName/quantity/price).
- `replenishment_payment_dto.dart` — `PaymentDto`.
- `replenishment_pay_order_response_dto.dart` — `PayOrderResponseDto { order: OrderDto, payment:
  PaymentDto }`.
- Request-side: a plain `Map<String, dynamic>` body built inline in the API source is sufficient
  for the POST bodies (matches the simplicity of the existing `getProducts()` call) — no request
  DTO class needed.

**API source** — `kiosk/lib/data/backend_api/sources/replenishment_orders_api.dart`:
```dart
class ReplenishmentOrdersApi {
  Future<OrderDto> createOrder({required String customerId, required List<({String productId, int quantity})> items});
  Future<List<OrderDto>> getOrders({required String customerId});
  Future<PayOrderResponseDto> payOrder(String orderId);
}
```
Provider `replenishmentOrdersApiProvider`, built on `replenishmentApiClientProvider` — same
pattern as `replenishmentProductsApiProvider`.

## Domain layer

**Entities** — `kiosk/lib/features/replenishment/entities/`:
- `replenishment_order.dart` — `ReplenishmentOrder` (`@MappableClass`): `id`, `customerId`,
  `customerName`, `customerEmail`, `status` (`ReplenishmentOrderStatus` enum: `pending`, `paid`,
  `cancelled`, with an `unknown` fallback for forward-compat), `total` (double, dollars), `currency`,
  `createdAt`, `updatedAt`, `items` (`IList<ReplenishmentOrderItem>`, empty when the source
  response omitted items).
- `replenishment_order_item.dart` — `ReplenishmentOrderItem`: `productId`, `productName`,
  `quantity`, `price` (double, dollars).
- `replenishment_payment.dart` — `ReplenishmentPayment`: `id`, `orderId`, `amount`, `currency`,
  `status`, `createdAt`.

**Mappers** — `kiosk/lib/features/replenishment/mappers/replenishment_order_mappers.dart`,
extension `toEntity` getters on `OrderDto`/`PaymentDto`, mirroring the existing
`replenishment_product_mappers.dart` style.

**Repository** — `kiosk/lib/features/replenishment/repositories/replenishment_orders_repository.dart`:
```dart
abstract class ReplenishmentOrdersRepository {
  Future<ReplenishmentOrder> createOrder({required String customerId, required List<ReplenishmentCartItem> items});
  Future<List<ReplenishmentOrder>> getOrders({required String customerId});
  Future<({ReplenishmentOrder order, ReplenishmentPayment payment})> payOrder(String orderId);
}
```

## State layer

- `replenishmentCheckoutProvider` — `AsyncNotifierProvider.autoDispose<ReplenishmentCheckoutNotifier, ReplenishmentOrder?>`.
  `build()` returns `null` (idle). `checkout()`:
  1. Reads `loginStateProvider`'s `Auth.id`; if unavailable, sets an `AsyncError` (surfaced via the
     existing `showNetworkErrorDialog` on the cart screen) rather than calling the API.
  2. Reads current `replenishmentCartProvider` items.
  3. Sets `AsyncLoading()`, calls `repository.createOrder(...)` via `AsyncValue.guard`.
  4. On success, clears the cart (`replenishmentCartProvider.notifier.clear()`).
  Modeled on `ChangePinNotifier` (`lib/features/auth/state/change_pin_notifier.dart`).

- `replenishmentOrdersProvider` — `AsyncNotifierProvider<ReplenishmentOrdersNotifier, List<ReplenishmentOrder>>`.
  `build()` fetches `getOrders(customerId: currentUserId)`. `refresh()` re-fetches. This provider is
  NOT autoDispose — it backs the top-bar badge, so it should stay alive while the Replenishment
  screen subtree is mounted (same lifetime as `replenishmentProductsProvider`).

- `replenishmentPendingOrdersCountProvider` — a plain `Provider<int>` computed from
  `replenishmentOrdersProvider`'s value (`.valueOrNull?.where((o) => o.status == pending).length ?? 0`).
  Used by the badge; returns 0 while loading/on error so the badge just doesn't show a number
  rather than erroring the app bar.

- `replenishmentPayOrderProvider` — `AsyncNotifierProviderFamily.autoDispose<ReplenishmentPayOrderNotifier, ({ReplenishmentOrder order, ReplenishmentPayment payment})?, String>`
  keyed by order id. `pay()` calls `repository.payOrder(orderId)` via `AsyncValue.guard`; on
  success, invalidates `replenishmentOrdersProvider` so the list/badge refresh to reflect the new
  status.

## UI changes

1. **`ReplenishmentCartScreen`** (`_CartTotalBar`): add a "Checkout" `Button` next to/below the
   total. While `replenishmentCheckoutProvider` `isLoading`, disable the button and swap its label
   for a small spinner (composed manually — `Button` has no built-in loading prop, matching how
   `payment_screen.dart`'s `_ConfirmButton` handles this today). `ref.listen` on
   `replenishmentCheckoutProvider`:
   - On new non-null data → show a success dialog (order id, item count, total). On dismiss, pop
     the cart route (`Navigator.of(context).pop()`), returning to `ReplenishmentScreen`.
   - On `AsyncError` → `showNetworkErrorDialog(context, error: error, onRetry: () =>
     ref.read(replenishmentCheckoutProvider.notifier).checkout())`.

2. **`ReplenishmentScreen`** top bar (`TopAppBar.trailing`): add a second icon (e.g.
   `Icons.receipt_long_rounded`) wrapped in a Material `Badge` showing
   `replenishmentPendingOrdersCountProvider` (hidden when 0), navigating to the new Orders route on
   tap. Placed alongside the existing refresh icon.

3. **New `ReplenishmentOrdersScreen`** (`kiosk/lib/features/replenishment/view/replenishment_orders_screen.dart`):
   - `state.when` over `replenishmentOrdersProvider`, same loading/error/empty scaffolding as
     `ReplenishmentScreen` (spinner, `_ErrorState` + retry, `_EmptyState`).
   - List of order cards: id (shortened), status chip (color-coded: pending = amber, paid = green,
     cancelled = grey), total, created date.
   - Pending orders get a "Pay Now" button. Tapping it calls
     `replenishmentPayOrderProvider(order.id).notifier.pay()`; button shows a spinner while that
     specific family instance is loading (so paying one order doesn't spinner-lock the whole list).
     On error, `showNetworkErrorDialog` with retry. On success, the list re-renders via the
     provider invalidation already wired into the notifier.
   - Paid/cancelled orders render the status chip only, no action.

## Navigation

New route `kiosk/lib/navigation/replenishment_orders_route.dart`:
```dart
part of 'router.dart';

@TypedGoRoute<ReplenishmentOrdersRoute>(path: '/replenishment/orders')
class ReplenishmentOrdersRoute extends GoRouteData with $ReplenishmentOrdersRoute {
  const ReplenishmentOrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ReplenishmentOrdersScreen();
}
```
Registered as a `part` in `router.dart` alongside the existing `replenishment_route.dart` /
`replenishment_cart_route.dart` parts; regenerated via `dart run build_runner build
--delete-conflicting-outputs`.

## Error handling summary

- Missing/unresolved current user at checkout time → `AsyncError` surfaced via
  `showNetworkErrorDialog`, no API call made.
- `createOrder` failure → cart is untouched (not cleared), retry re-submits the same cart.
- `payOrder` failure → order stays `pending`, retry re-attempts pay for the same order id, no
  duplicate orders created.

## Testing

No automated test infra currently covers `lib/features/replenishment/` (per project convention,
this app is verified via `dart analyze` + manual run per `kiosk/CLAUDE.md`'s UI-focused scope) —
this spec follows the same verification approach: `dart analyze` clean, manual smoke test of
checkout → success dialog → Orders screen → pay → status flips to paid.
