# Chained first-run setup flow (mobile)

**Date:** 2026-09-01
**Scope:** `mobile/lib/features/dashboard/view/dashboard_screen.dart` (single file)
**Status:** Approved

## Problem

On a freshly installed app, the dashboard shows three onboarding prompts:

1. **Set Up Store** (`StoreDetailsDialog`) — when `storeInfoProvider` has an empty `storeName`
2. **No Employees Added** (`showSetupPromptDialog`) — when `usersProvider` has `length <= 1`
3. **No Products Found** (`showSetupPromptDialog`) — when `inventoryNotifierProvider` has an empty product list

Each check (`checkAndShowStoreDetailsDialog`, `checkAndShowEmployeesDialog`,
`checkAndShowProductsDialog`) is guarded only by its own `hasShown*` ref. All three
are invoked back-to-back from every `ref.listen` handler and from the post-frame
`useEffect`. Nothing gates them on one another, so all three dialogs open and stack
on top of each other — the store form ends up buried under the employees and
products prompts.

## Goal

Run the first-run setup as a **fully chained sequence**: store setup → employees →
products. Only one prompt is visible at a time, and each step only appears once the
previous step is satisfied.

## Design

Replace the three `checkAndShow*` functions with a single ordered gate,
`checkAndShowSetupFlow()`, that shows **at most one** dialog per invocation.

### Step evaluation (in order; first unsatisfied step wins)

1. **Guard** — return if `user?.isAdmin != true`, or if `isSetupDialogOpen.value`
   is already `true`.
2. **Store** — read `storeInfoProvider`. If `isLoading`/`hasError`/`value == null`,
   return (wait for it to resolve). If `value.storeName.trim().isEmpty` → open
   `StoreDetailsDialog`, return.
3. **Employees** — skip if `hasShownEmployeesDialog.value`. Otherwise read
   `usersProvider`. If `isLoading`/`hasError`/`value == null`, return. If
   `value.length <= 1` → open the "No Employees Added" prompt (skippable), return.
4. **Products** — skip if `hasShownProductsDialog.value`. Otherwise read
   `inventoryNotifierProvider`. If `isLoading`/`hasError`/`value?.products == null`,
   return. If `products.isEmpty` → open the "No Products Found" prompt (skippable),
   return.

Store setup is mandatory (only "Save" or "Sign Out"). The employees and products
prompts each gain a "Skip for now" tertiary button and, once shown, do not
re-appear for the rest of the session.

### Chaining mechanism

- A new `isSetupDialogOpen` ref (bool) is set to `true` immediately before any
  setup dialog is shown.
- Each dialog future gets `.whenComplete(() { isSetupDialogOpen.value = false;
  checkAndShowSetupFlow(); })`, so completing one step immediately re-evaluates and
  advances to the next. This re-check is required, not just an optimisation:
  `StoreDetailsDialog.onSave` updates `storeInfoProvider` *before* it pops itself,
  so the `ref.listen` fired by that state change still sees `isSetupDialogOpen ==
  true` and bails — the `whenComplete` re-check is what actually advances to the
  employees step.
- The three `ref.listen` handlers (`storeInfoProvider`, `usersProvider`,
  `inventoryNotifierProvider`) and the post-frame `useEffect` each call
  `checkAndShowSetupFlow()` once instead of all three old functions.

### Ref changes

| Ref | Change | Reason |
|---|---|---|
| `hasShownStoreDetailsDialog` | **removed** | Store dialog is non-dismissible and mandatory; the gate + `isSetupDialogOpen` + provider truth (`storeName` non-empty after save) prevent re-showing. |
| `hasShownEmployeesDialog` | **kept** | Employees prompt is now skippable ("Skip for now"); must not re-nag after a skip. Also covers "Add Employee", which pops the dialog and navigates to `/users` *before* any employee exists, so `users.length <= 1` is still true when `whenComplete` re-checks. |
| `hasShownProductsDialog` | **kept** | Products prompt has "Skip for now"; must not re-nag after the admin skips it within a session. |
| `isSetupDialogOpen` | **added** | Prevents a provider change from stacking a second dialog while one is open. |

### Unchanged

Every dialog keeps its `barrierDismissible` value and its sign-out / import /
navigation actions. The sequencing between the three prompts changes, and the
employees prompt gains a "Skip for now" tertiary button (and a reworded message)
to match the products prompt.

## Verification

- `dart analyze` clean.
- Manual reasoning about the fresh-install path: store form shows alone → on Save,
  employees prompt shows alone → on adding an employee and returning to dashboard,
  products prompt shows alone → Import or Skip completes the flow.

## Out of scope

- Backend changes.
- The kiosk (`kiosk/`) app — mobile only for now.
- New tests (per project convention, verified via `dart analyze`).
