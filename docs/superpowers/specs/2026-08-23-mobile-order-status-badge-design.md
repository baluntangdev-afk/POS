# Mobile Order Status Badge

## Problem

The mobile Orders screen (`mobile/lib/features/orders/view/orders_screen.dart`) shows a fulfillment-type chip (On-site/Pickup/Delivery) but no order status (pending/preparing/ready/fulfilled/cancelled), even though `OrderData.status` is already available on every `OrderEvent`. The kiosk app already solves this with a color-coded status system; mobile should reuse the same classification and color mapping so the two apps read consistently.

## Design

### `order_status.dart` (new — `mobile/lib/features/orders/view/order_status.dart`)

Mirrors kiosk's `kiosk/lib/features/orders/view/order_status.dart`:

- `enum OrderCardStatus { pending, preparing, ready, cancelled, fulfilled, unknown }`
- `classifyOrderStatus(OrderEvent event)` — returns `cancelled` if `event.type == OrderEventType.cancelled`, otherwise switches on `event.data.status.toLowerCase()` (`pending`, `preparing`, `ready`, `fulfilled`, `cancelled`), falling back to `unknown` for anything else.
- `orderStatusPillStyle(OrderCardStatus status)` — returns `(String label, Color color)`:
  - `pending` / `preparing` → `('Pending'/'Preparing', AppColors.warning)`
  - `ready` → `('Ready', AppColors.success)`
  - `fulfilled` → `('Fulfilled', AppColors.primary)`
  - `cancelled` → `('Cancelled', AppColors.error)`
  - `unknown` → `('Unknown', AppColors.textSecondary)` — caller substitutes the raw status string for the label so nothing is silently hidden, same convention as kiosk.

Mobile's `AppColors` already carries the same semantic tokens as kiosk's `ColorSet` (`success`, `warning`, `error`≈`danger`, `primary`), so no new color constants are needed.

### `orders_screen.dart` changes

- New private `_StatusBadge` widget: small pill, outlined border in the status color, uppercase label text in the status color (matches kiosk's outlined badge style — not filled, since mobile has no "actionable/dropdown" state to distinguish).
- `_OrderCard`: add `_StatusBadge` before the existing `_FulfillmentChip` in the row (`_FulfillmentChip` stays for fulfillment type; badge is additive, not a replacement).
- `_OrderDetailSheet`: add the same `_StatusBadge` next to the "Order #id" heading.

### Out of scope

- No status-change UI (dropdown/menu) — mobile is a read-only live feed, unlike kiosk's staff-facing board. This is display-only.
- No backend/API changes — `OrderData.status` and `OrderEventType` already carry everything needed.
- No new providers or dependencies.

## Testing

- `dart analyze` (mobile is a read-only viewer app; no backend testing per project convention — see `be/` scope note in memory).
- Manual visual check: run the app, confirm badge colors match kiosk for each status, confirm unknown/cancelled fallbacks render sensibly.
