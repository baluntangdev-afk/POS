# Order card detail + tap-to-open detail sheet

**Date:** 2026-09-08
**App:** `mobile_merchant/`
**Status:** Implemented

## Problem

The Orders screen card currently shows only `Order #<id>`, a customer label, a
clock time, an `"N items"` count, and the total. Merchants can't see what was
ordered or where it's going without another screen. The screenshots supplied
show the kiosk card, which lists every line item, an order-type/location line
(`On-site · Conference Meeting Hall`), and a relative timestamp (`2m ago`).

The webhook payload already carries the missing data (`fulfillment_type`,
`facility_name`, `district_name`) — the sibling `mobile/` app models it, but
`mobile_merchant`'s `OrderDataDto` drops it. No backend change is needed.

## Goals

1. Each order card shows: customer · fulfillment · facility line, a relative
   timestamp, the full line-item list with per-line price, and the Total.
2. Tapping a card opens a read-only bottom sheet with the expanded order
   detail.
3. The status pill and Cancel button stay on the card (unchanged behaviour).

## Non-goals

- No backend/webhook change.
- No actions in the bottom sheet (it is read-only).
- No new automated tests (project convention — verify with `dart analyze`).
- No change to tab filtering, dedupe, or the live-feed pipeline.

## Approach

Port the dropped fields from `mobile/`, persist them in the local cache, and
rebuild the card + add a detail sheet. (Rejected: skipping persistence — stale
cards would lose the fulfillment line; storing a raw JSON blob — rewrites every
DAO method for no present benefit.)

## Changes

### Data layer

**`lib/features/orders/data/models/order_data_dto.dart`**
- Add `enum FulfillmentType { onSite, pickup, delivery, other }` with a lenient
  `static FulfillmentType fromWire(String?)` (`on_site` / `pickup` / `delivery`;
  anything else → `other`) and a `String get wireValue` inverse for local
  persistence round-tripping.
- Add fields: `final FulfillmentType fulfillmentType;`, `final String?
  facilityName;`, `final String? districtName;`. Ctor: `fulfillmentType`
  defaults to `FulfillmentType.other` (keeps existing test call sites
  compiling), the two names stay optional/nullable like `customerName`.
- `fromJson`: parse `fulfillment_type`, `facility_name`, `district_name`.
- `fromWireJson`: same, via `FulfillmentType.fromWire`.

**`lib/core/database/tables/order_events_table.dart`**
- Add `TextColumn get fulfillmentType => text().nullable()();`
  (store `wireValue`), `TextColumn get facilityName => text().nullable()();`,
  `TextColumn get districtName => text().nullable()();`.

**`lib/core/database/app_database.dart`**
- `schemaVersion` 3 → 4.
- `onUpgrade`: `if (from < 4) { await m.addColumn(orderEventsTable,
  orderEventsTable.fulfillmentType); ...facilityName; ...districtName; }`.

**`lib/core/database/daos/order_events_dao.dart`**
- `replaceAll` + `upsertLiveEvent` inserts/updates: write the 3 columns
  (`fulfillmentType: Value(event.data.fulfillmentType.wireValue)` etc.).
- `_toDto`: read them back — `fulfillmentType:
  FulfillmentType.fromWire(e.fulfillmentType)`, `facilityName: e.facilityName`,
  `districtName: e.districtName`.

**`lib/features/orders/state/orders_notifier.dart`**
- `_withStatus` rebuilds `OrderDataDto` field-by-field — add the 3 new fields
  (pass through from `d`).

**Codegen:** `dart run build_runner build --delete-conflicting-outputs`
(regenerates `app_database.g.dart`, `order_events_dao.g.dart`).

### UI layer

**`lib/features/orders/presentation/widgets/order_card.dart`**
- Wrap the card `Container` in `Material` + `InkWell(onTap: widget.onTap)` with
  matching border radius. Add `final VoidCallback onTap;` to the widget.
- Subtitle line (replaces the bare customer `Text`): join with ` · ` —
  - customer: `customerName` if non-empty else `Guest`
  - fulfillment: `switch (fulfillmentType)` → `onSite` → `On-site` +
    (` · <facilityName>` when non-empty), `pickup` → `Pickup`, `delivery` →
    `Delivery`, `other` → omitted (null, filtered out)
- Replace `_formatTime` clock with `_relativeTime(data.createdAt)` →
  `just now` / `Nm ago` / `Nh ago` / `Nd ago`.
- Replace the `"N items"` + total row with:
  - a `Column` of item rows: `Row[ Text('${qty}×'), SizedBox,
    Expanded(Text(productName, ellipsis)), Text('₱${(price*qty)}') ]`
  - `Divider`
  - Total row: `Text('Total')` + `Text('₱${total}', bold, primary)` (kept
    style).
  - When `items` is empty: skip the item column + divider, keep the Total row.
- Keep the Cancel button block unchanged.

**`lib/features/orders/presentation/widgets/order_detail_sheet.dart`** (new)
- `void showOrderDetailSheet(BuildContext, OrderEventDto)` → `showModalBottomSheet`
  (`isScrollControlled: true`, `backgroundColor: Colors.transparent`).
- `_OrderDetailSheet` `StatelessWidget`: `SafeArea` → rounded-top `Container`
  (`AppSpacing.radiusLg`), `Column(mainAxisSize: min)`:
  - grab handle (36×4, `AppColors.border`, pill)
  - header `Row`: `Expanded(Text('Order #${data.id}', titleLarge))` +
    non-interactive `_StatusBadge`
  - subtitle line + relative time (same builder as the card, factored into a
    shared helper)
  - `data.customerEmail` line when non-empty
  - `data.districtName` line when non-empty
  - item rows: `${qty}×  name` on the left, `₱unit × qty = ₱line` — show unit
    price and line total
  - `Divider`, Total row
- `_StatusBadge` is currently private to `order_card.dart`. Extract it to a new
  `lib/features/orders/presentation/widgets/order_status_badge.dart` (rename to
  `OrderStatusBadge`) so both the card and the sheet use it. Card keeps its
  interactive usage; sheet uses the read-only form.

**`lib/features/orders/presentation/widgets/orders_body.dart`**
- Pass `onTap: () => showOrderDetailSheet(context, event)` to `OrderCard`.

## Edge cases

| Case | Behaviour |
|---|---|
| `fulfillment_type` missing / unrecognized | `FulfillmentType.other`, segment omitted from subtitle |
| `on_site` with no `facility_name` | subtitle shows just `On-site` |
| empty `items` | card/sheet skip the item list + divider, Total still renders |
| long product name | `Expanded` + `TextOverflow.ellipsis`, price stays visible |
| cancelled / fulfilled order | no Cancel button (unchanged); card still opens the sheet |
| cache restored from a pre-v4 DB row | new columns read as `null` → `other` / no facility; heals on next fetch |

## Verification

- `dart run build_runner build --delete-conflicting-outputs`
- `dart analyze` — clean (no new warnings)
