# Ordering Screen — Order Panel Redesign

**Date:** 2026-06-04  
**Status:** Approved

---

## Goal

Replace the existing mini-cart panel and sticky cart bar in `ordering_screen.dart` with a unified `_OrderPanel` that:

1. Shows all added items in a scrollable list on the right side of the screen.
2. Lets the cashier tap any item to expand inline edit controls (quantity, per-item order type, notes) without navigating away.
3. Adapts responsively — wide screens show the panel permanently alongside the product grid; narrow screens hide the panel behind a floating cart button that opens a modal bottom sheet.

---

## Responsive Behaviour

| Breakpoint | Layout |
|---|---|
| **Kiosk** (`≥ kiosk` breakpoint) | Persistent split — product grid (left, flexible) + order panel (right, fixed width) always visible side by side |
| **Tablet** (medium breakpoint) | Same as kiosk if horizontal space allows; falls back to full-width product grid + floating cart FAB bottom-right that opens `_OrderPanelSheet` (modal bottom sheet, ~70% screen height) |
| **Phone** | Full-width product grid + floating cart FAB + same modal bottom sheet |

The split is shown when `responsive.breakpoint >= Breakpoint.tablet` **and** the screen width is wide enough that the order panel does not squeeze the product grid below a comfortable minimum (check via `LayoutBuilder` with a threshold, e.g. `constraints.maxWidth >= 720`).

---

## Data Model Changes

### `LineItem` entity (`kiosk/lib/features/sales/entities/line_item.dart`)

Add two optional fields:

```dart
final SaleType? itemSaleType;   // per-item override; null = inherits sale-level type
final String? notes;
```

- `SaleType` already exists in `kiosk/lib/features/sales/enums/sale_type.dart` (`dineIn`, `takeOut`).
- Both fields are nullable to remain backward compatible with items added before this change.
- `@MappableClass` annotation means `build_runner` must be re-run after the change to regenerate `line_item.mapper.dart`.

No backend changes — these fields are purely UI/local state for the cashier and are not sent to the server in the current flow.

---

## New / Changed Widgets

### `_OrderPanel` (new, replaces `_MiniCartPanel` + `_StickyCartBar`)

A `ConsumerStatefulWidget` that renders the full order panel:

- **Header row:** cart icon + "Order" label + item-count badge.
- **Scrollable item list:** one `_OrderItemRow` per `LineItem`.
- **Total row + Checkout button** pinned at the bottom.

Used directly in the kiosk/tablet split layout inside `Row(children: [..., _OrderPanel()])`.

### `_OrderItemRow` (new)

A `HookConsumerWidget` with two visual states driven by a local `selectedItemId` state held in `_OrderPanel`:

**Collapsed (not selected):**
- Product name (bold), modifiers summary (one line, muted), quantity badge, per-item sale type badge (Dine In / Take Out), total price.
- Tapping expands the row.

**Expanded (selected):**
- Teal highlight border + tinted background.
- Quantity stepper (− / count / +) inline.
- Trash icon (removes item immediately via `orderingProvider.notifier.removeLineItem`).
- **Order Type pill toggle:** two-segment pill, "Dine In" ↔ "Take Out". Default inherits sale-level type. Tapping saves via `replaceLineItem`.
- **Notes text field:** single-line `TextField`, placeholder `"e.g. extra rice, no onions..."`. Changes saved on `onEditingComplete` / `onTapOutside`.
- Tapping the expanded row header collapses it.

### `_OrderPanelSheet` (new)

Wraps `_OrderPanel` in a `DraggableScrollableSheet` for the narrow-screen case. Launched from the floating cart FAB via `showModalBottomSheet`.

### `_CartFab` (new, replaces `_StickyCartBar` + `_CartButton` on narrow screens)

A `FloatingActionButton.extended` shown bottom-right when the order panel is hidden. Displays item count + total. Tapping opens `_OrderPanelSheet`.

---

## Layout Changes in `ordering_screen.dart`

### `_TabletLayout` / `_KioskLayout`

Both layouts are consolidated under a single adaptive layout widget `_AdaptiveOrderingLayout` that uses `LayoutBuilder`:

```
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth >= 720) {
    // split: product area + _OrderPanel
  } else {
    // full product area + _CartFab
  }
})
```

`_KioskLayout` and `_LandscapeLayout` (currently unused in production — all breakpoints route to `_TabletLayout`) are retained but their usage in `OrderingScreen` is replaced by `_AdaptiveOrderingLayout`.

---

## State Management

No new providers. All edits use existing `orderingProvider.notifier` methods:

- `replaceLineItem(updatedItem, index: i)` — used when order type or notes change.
- `removeLineItem(index: i)` — used when trash icon tapped.

The selected/expanded item index is **local UI state** only (`useState<int?>` in `_OrderPanel`), not stored in Riverpod. It resets to `null` when the panel closes or an item is removed.

---

## Files to Change

| File | Change |
|---|---|
| `entities/line_item.dart` | Add `itemSaleType` and `notes` fields |
| `entities/line_item.mapper.dart` | Regenerated by `build_runner` — do not edit manually |
| `view/ordering_screen.dart` | Replace `_MiniCartPanel`, `_StickyCartBar`, `_CartButton` with `_OrderPanel`, `_OrderItemRow`, `_OrderPanelSheet`, `_CartFab`, `_AdaptiveOrderingLayout` |

No changes to: `ordering_notifier.dart`, `line_item_dialog.dart`, `cart_screen.dart`, backend, router.

---

## Acceptance Criteria

- [ ] On wide screens (≥ 720 logical px): order panel is always visible alongside the product grid.
- [ ] On narrow screens (< 720 logical px): floating cart FAB visible; tapping opens the bottom sheet order panel.
- [ ] Tapping a cart item expands it; tapping again or tapping another item collapses it.
- [ ] Quantity stepper updates item total in real time.
- [ ] Order type toggle (Dine In / Take Out) is saveable per item.
- [ ] Notes field accepts free text; saved on blur/submit.
- [ ] Removing an item via trash icon removes it from the list and collapses expanded state.
- [ ] Collapsed item shows order-type badge and notes preview (truncated to 1 line).
- [ ] All existing navigation (Back button, Checkout button) works as before.
- [ ] No RenderFlex overflow on any supported screen size.
