# Dashboard Toolbar — Design

**Date:** 2026-09-04
**Status:** Approved

## Goal

Port the top toolbar (`_Header`) from the `mobile/` app's dashboard onto
`mobile_merchant`'s dashboard screen. Copy the toolbar setup only — **not** the
menu/tile grid.

## Scope

Reduced from `mobile`'s header to **brand + clock only**:

- No greeting text
- No user pill (name/role/avatar)
- No Sign Out button
- No live-orders status pill
- No menu grid

Rationale: `mobile_merchant` has no auth/user feature and no live-orders socket
yet. Those pieces are dropped until the corresponding features exist.

## Files

| File | Change |
|---|---|
| `lib/features/dashboard/presentation/widgets/dashboard_toolbar.dart` | **New** — `DashboardToolbar` + private `_Brand`, `_Clock` |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | **Edit** — replace `AppScaffold` with plain `Scaffold` + `SafeArea` + `Column(toolbar, Expanded placeholder)` |

## Components

### `DashboardToolbar` (StatelessWidget)

- `Container`: `AppColors.surface` background, bottom `BorderSide(AppColors.border)`,
  soft `boxShadow`, fixed height ~64.
- `LayoutBuilder`: horizontal padding `28` when width > 600 else `16`; the clock
  block is hidden when width < 480.
- `Row`: `_Brand` — `Spacer` — (width ≥ 480 only) 1px vertical divider + `_Clock`.

### `_Brand` (StatelessWidget)

- 34×34 rounded container, gradient `AppColors.primary → AppColors.primaryDark`,
  `Icons.shopping_cart_rounded` (white, 18).
- Two-tone "Cartivo" wordmark via `GoogleFonts.inter` — "Carti" in
  `AppColors.textPrimary`, "vo" in `AppColors.primary`, size 18, w700,
  letterSpacing -0.4.

### `_Clock` (StatefulWidget)

- `Timer.periodic(Duration(seconds: 30))` in `initState`, cancelled in `dispose`,
  `setState` updates a `DateTime _now` field.
- Line 1: `h:mm AM/PM` — size 15, w700, `AppColors.textPrimary`.
- Line 2: `Day, Mon D` (e.g. `Thu, Sep 4`) — size 11, w400, `AppColors.textSecondary`.
- Same date/time formatting logic as `mobile`'s `_Clock`.

## Tokens

All colors, spacing, radii, and typography go through `AppColors` / `AppSpacing`
/ `AppTextStyles` / `GoogleFonts.inter`. No raw color or pixel literals beyond
the small geometric constants already idiomatic in this codebase (icon sizes,
gradient stops that map to tokens).

## Verification

`dart analyze` only. No app run, no new test files.
