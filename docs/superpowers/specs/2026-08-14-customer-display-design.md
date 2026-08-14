# Dual-monitor customer display (design)

## Current state

- The kiosk is a single-window Windows app. `kiosk/lib/bootstrap.dart` initializes
  `window_manager` and sizes/positions one window covering the primary display;
  `kiosk/lib/app.dart` wraps it in `_WindowCloseGuard` (confirm-before-exit). There is no second
  window anywhere in the codebase today.
- The live cart/order is already single-sourced: `orderingProvider`
  (`kiosk/lib/features/sales/state/ordering_notifier.dart`, an `AsyncNotifier<OrderingData>`)
  holds the in-progress `Sale`, whose `items: IList<LineItem>` and computed getters
  (`grossAmount`, `discountAmount`, `vatAmount`, `totalAmount`) already drive every cashier screen.
  Cart-empty already means "no active order" throughout the app — `ref.invalidate(orderingProvider)`
  (used on New Order / receipt close) rebuilds to a fresh empty `Sale`, which is the existing
  reset-to-idle mechanism.
- `screen_retriever` (multi-monitor query API) is already present as a *transitive* dependency,
  pulled in by `window_manager`, and is already registered in the native Windows plugin registrant
  (`kiosk/windows/flutter/generated_plugin_registrant.cc`). It is not currently imported by any
  Dart code and is not a direct `pubspec.yaml` dependency.
- `kiosk/windows/runner/` already carries one precedent for a Dart feature backed by custom native
  runner code: `touch_keyboard_guard.cpp` + `MethodChannel('pos_kiosk/touch_keyboard')`
  (`kiosk/lib/utils/windows_touch_keyboard.dart`), registered in `main.cpp`. This feature does
  **not** need the same treatment — see "Native runner change" below.
- `Store` (`kiosk/lib/features/sales/entities/store.dart`) already carries `legalName` and an
  optional `logo`. `Receipt` already carries `docNumber`. Both are reused as-is.

## Goals

1. On a single-monitor kiosk, behavior is **unchanged** — no second window is created, no new
   dependency runs, no measurable overhead.
2. On a dual-monitor kiosk, monitor 2 shows a read-only, cashier-independent customer display that
   mirrors the state of the current order (idle when there is none, itemized + totals while one is
   in progress, a brief thank-you after payment), and never accepts input.
3. The cashier window's behavior, focus, and input handling are unaffected whether or not the
   customer display exists or is currently alive.
4. A failure of the customer display (window closed, killed, or a Dart-level exception/crash in
   its own UI code) can never block or degrade the cashier's ability to process a sale. See
   "Isolation model" below for the precise boundary of this guarantee — it is engine-level, not
   OS-process-level.
5. No new cart/order model — the customer display is a pure, read-only projection of
   `orderingProvider`'s existing `Sale`/`LineItem` entities.

## Non-goals (this pass)

- No promotional banner / rotating media support on the idle screen — logo + store name + welcome
  message only, per your answer during design.
- No customer-facing interactivity of any kind (no "confirm my order," no tipping, no signature) —
  explicitly read-only, matching the original ask.
- No product images in the order line items — text-only rows (qty × name — price), matching the
  original mockup's distance-readable, minimal-text style.
- No non-Windows platform work (macOS numbers throughout this doc assume Windows-only; the kiosk
  targets Windows in production per `CLAUDE.md`).

---

## Approach chosen: `desktop_multi_window`, confirmed with you

Three approaches were considered:

1. **`desktop_multi_window` (chosen).** Creates the customer display as a second native window
   backed by its own `FlutterEngine`/`FlutterViewController`, communicating with the cashier via
   method channels scoped per window id. Same publisher family (MixinNetwork/Leanflutter ecosystem)
   as `window_manager` and `screen_retriever`, already depended on; actively maintained;
   purpose-built for exactly this scenario — window creation, positioning primitives, and
   per-window messaging are handled by the package instead of hand-rolled.
2. **Hand-rolled second `FlutterViewController` in the same process.** Rejected — this is what
   `desktop_multi_window` already does, correctly and maintained, under the hood. Reimplementing
   it ourselves in `windows/runner/` would be strictly worse for zero benefit.
3. **Fully separate second application (own `.exe`, real OS-process isolation).** Rejected —
   maximum isolation, but doubles the build target, installer entry, and requires hand-rolled IPC
   (named pipe/socket). Confirmed with you after the isolation-model correction below; the residual
   same-process risk was judged acceptable against that cost.

## Isolation model (corrected from the original draft of this spec)

**`desktop_multi_window` does not spawn a separate OS process on Windows.** Verified directly
against the package's native source (`desktop_multi_window`'s `windows/multi_window_manager.cc`):
each additional window is a second `FlutterEngine`/`FlutterViewController` created *inside the
same process* as the cashier window — same `.exe`, same address space, no `CreateProcess` involved.
This was originally assumed to give OS-level crash isolation; it does not.

What the isolation actually is:
- **Contained**: Dart-level exceptions (unhandled errors, widget build failures, state bugs — the
  overwhelming majority of real bugs) are caught per-engine by Flutter's own error handling. The
  cashier's own `FlutterError.onError` override in `kiosk/lib/bootstrap.dart:16-22` is a working
  precedent for this containment already existing in this codebase, applied per-engine to the
  customer-display's own entrypoint.
- **Not contained**: a genuine native-level fault (access violation, stack overflow, engine-level
  crash) in the customer-display engine is shared-fate with the whole process, cashier included —
  because they share an address space. This is a small, residual risk, and one already shared by
  "any plugin in this app misbehaving natively" today; going to true process isolation (approach 3
  above) was evaluated and declined for cost.

## Architecture

```
pos_app.exe (single process)
┌────────────────────────────────┐              ┌────────────────────────────────┐
│ Cashier engine (main window)     │              │ Customer-display engine         │
│                                  │  WindowController │ (2nd FlutterEngine, created by │
│ orderingProvider                 │  .invokeMethod    │  desktop_multi_window)         │
│  Sale.items / totals             │  ('sync', ...)     │                                │
│                                  │───────────────▶   │ own ProviderContainer          │
│ CustomerDisplayHost               │                    │  (theme only — no repos,       │
│  - ref.listen(orderingProvider)   │                    │   no backend access)           │
│  - builds CustomerDisplaySnapshot │                    │                                │
│  - screen_retriever monitor       │                    │ CustomerDisplayReceiver        │
│    detection + window lifecycle   │                    │  - setWindowMethodHandler      │
└────────────────────────────────┘                    │  - holds latest snapshot        │
                                                          │                                │
                                                          │ CustomerDisplayPage            │
                                                          │  switches on snapshot variant: │
                                                          │  IdleCustomerView /            │
                                                          │  OrderCustomerView /           │
                                                          │  ThankYouCustomerView          │
                                                          └────────────────────────────────┘
```

The cashier engine's existing code (`bootstrap.dart`, `app.dart`, `orderingProvider`, every
mutation call site) is untouched except for one new listener wired in. The customer-display engine
runs a distinct Dart entrypoint that never touches the cashier's `ProviderContainer`,
`router.dart`, or any repository/API code — it has no backend access and needs none, even though
it runs in the same OS process (see "Isolation model" above).

## New feature module

Follows the existing `lib/features/<domain>/{entities,state,view}` convention:

```
lib/features/customer_display/
├── entities/
│   └── customer_display_snapshot.dart   # @MappableClass, JSON (de)serializable over IPC
├── state/
│   ├── customer_display_host.dart       # cashier-side: listens + pushes + owns window lifecycle
│   └── customer_display_receiver.dart   # display-side: setWindowMethodHandler + holds snapshot
└── view/
    ├── customer_display_page.dart
    ├── idle_customer_view.dart
    ├── order_customer_view.dart
    └── thank_you_customer_view.dart
```

No `repositories/` — this module is IPC-driven, not API-driven.

### `CustomerDisplaySnapshot`

```dart
sealed class CustomerDisplaySnapshot {
  const factory CustomerDisplaySnapshot.idle({required String storeName, String? storeLogo}) = _Idle;
  const factory CustomerDisplaySnapshot.ordering({
    required IList<CustomerDisplayLineItem> items,
    required Decimal subtotal,
    required Decimal discount,
    required Decimal tax,
    required Decimal total,
  }) = _Ordering;
  const factory CustomerDisplaySnapshot.thankYou({required String docNumber}) = _ThankYou;
}

class CustomerDisplayLineItem {
  final String productName;
  final int quantity;
  final String? variantLabel;   // e.g. "Large" — omitted if the default/only variant
  final Decimal lineTotal;
}
```

Built in `CustomerDisplayHost` from `Sale`/`LineItem` (`.ordering`) or `Receipt` (`.thankYou`) —
these are the only two places pricing/labels are computed, both already existing entity logic, not
reimplemented.

## Data flow

1. Cashier mutates `orderingProvider` via existing call sites (`addLineItem`, `replaceLineItem`,
   `removeLineItem`, `applyDiscount`, `clearLineItems`, etc.) — **zero changes** to any of them.
2. `CustomerDisplayHost.ref.listen(orderingProvider, ...)` fires, builds a fresh
   `CustomerDisplaySnapshot` from the new `Sale`, and calls
   `_windowController.invokeMethod('sync', snapshot.toMap())` on the `WindowController` returned by
   `WindowController.create(...)` when the display window was created. Debounced to the next frame
   (`addPostFrameCallback`), not per keystroke/tap, so a burst of rapid cart edits collapses to one
   push.
3. `sale.items.isEmpty` → snapshot is `.idle(...)`. This covers every existing "back to nothing"
   path (new order, receipt close, cart cleared) for free, since they all already route through
   `orderingProvider` going back to an empty `Sale` — no separate "cancel" signal is needed.
4. `confirmSale()` resolving with a non-null `receipt` → host pushes `.thankYou(receipt.docNumber)`
   once. The display side shows it for 5 seconds (per your answer) and then transitions itself
   locally back to idle — it does not wait for a further push, since the cashier has typically
   already `ref.invalidate(orderingProvider)`'d by then (see `receipt_screen.dart`'s New Order/Close
   handlers) and there's no guarantee of a second `.idle()` push arriving inside that window.
5. On the display side, `CustomerDisplayReceiver`'s method handler is the *only* write path into its
   local snapshot state — the display never calls back into the cashier at all. Liveness is
   inferred by the cashier side from `onWindowsChanged`/`WindowController.getAll()` (see "Failure &
   recovery"), not from any message the display sends. It cannot mutate the order.

## Monitor detection

- `screen_retriever` is promoted from transitive to a direct `pubspec.yaml` dependency (already
  natively registered — no other native change needed for detection itself).
- `CustomerDisplayHost` calls `screenRetriever.getAllDisplays()`:
  - **1 display** → do nothing. No window is created, no polling overhead beyond the check itself.
  - **2+ displays** → create the customer-display window via `desktop_multi_window`, positioned on
    the first non-primary display's bounds, `setFullScreen`/maximized.
- **Live hot-plug** (per your answer): confirmed against `screen_retriever`'s actual source
  (`ScreenRetriever.addListener`/`ScreenListener.onScreenEvent(String eventName)`) — a real
  display-change listener API exists, so this is event-driven, not polled. `CustomerDisplayHost`
  registers a `ScreenListener` and re-runs `getAllDisplays()` to reconcile whenever any event
  fires (the exact `eventName` values aren't asserted on — any event is treated as "recheck
  displays," which is robust to not knowing the full set of possible values up front).
  - Monitor count 1 → 2 while running: create the window.
  - Monitor count 2 → 1 while running: close the window (see "Window behavior").

## Native runner change

**None needed.** Confirmed against `desktop_multi_window`'s actual native source
(`windows/multi_window_manager.cc`): window creation is handled entirely inside the plugin's own
native code, invoked from Dart via its method channel — the same auto-registration mechanism
already used by `screen_retriever_windows` in `generated_plugin_registrant.cc` today. Adding the
package to `pubspec.yaml` and running `flutter pub get` is sufficient; `kiosk/windows/runner/main.cpp`
is untouched. (The original draft of this spec assumed a `main.cpp` branch modeled on
`touch_keyboard_guard.cpp` — that assumption didn't hold once the actual source was checked.)

## Window behavior

- The customer-display engine positions and shows *itself* — `window_manager` is engine-scoped, so
  calling `windowManager.xxx()` from inside the customer-display entrypoint controls that window,
  not the cashier's (this is the same package/pattern `bootstrap.dart` already uses for the cashier
  window, just running inside the second engine). It sets its own bounds to the target display's
  `visiblePosition`/`size` (from `screen_retriever`), calls `setFullScreen(true)`, then
  `windowManager.show(inactive: true)` — `inactive: true` is the confirmed flag (verified in
  `window_manager`'s own source) for "become visible without taking focus," which is what keeps the
  cashier window active at all times.
- No navigation chrome, no POS controls, no payment controls — enforced simply by
  `CustomerDisplayPage` never rendering any interactive widget, not by disabling input handling
  (there's nothing to disable).
- No explicit "prevent the customer window from being closed" handling — see recovery below,
  which already has to handle the window disappearing for any reason (closed, crashed engine-side,
  or deliberately), so a special case for user-initiated close would be redundant.

## Failure & recovery

- **Detecting death**: `desktop_multi_window` exposes `onWindowsChanged` (a stream that fires when
  any window is created or destroyed) and `WindowController.getAll()` (the current live window
  list) — both confirmed in the package's own source. `CustomerDisplayHost` listens to
  `onWindowsChanged` and reconciles against `getAll()`: if the display window's id is no longer
  present, it's gone. `invokeMethod` calls failing with a `WindowChannelException` (also confirmed
  in source) are treated as a secondary signal for "unreachable," in case the destroy event is ever
  missed.
- **Recreate (per your answer)**: once treated as gone, `CustomerDisplayHost` discards the stale
  `WindowController` and attempts to recreate the window on the next detection cycle, as long as 2+
  monitors are still present. Bounded retry with backoff (not a tight loop) so a genuinely absent
  second monitor doesn't spin.
- **Blast radius**: every step above lives entirely inside `CustomerDisplayHost`. It never throws
  into, blocks, or is awaited by any cashier-critical path (`confirmSale`, payment, printing). At
  most, a failure is logged. The cashier UI shows no dialog, no banner, no degraded state tied to
  the customer display's health. (This covers the Dart-level failure modes described in "Isolation
  model" above — it does not and cannot cover a shared-process native crash, which takes the whole
  app down regardless of what `CustomerDisplayHost` does.)
- **App restart**: `CustomerDisplayHost` re-runs its startup detection from scratch on every launch
  — no persisted "did I have a customer display last time" state, so a fresh boot always
  re-derives the correct behavior from the currently connected monitors.

## Testing plan

- **Unit** (no window/IPC involved):
  - `Sale`/`LineItem` → `CustomerDisplaySnapshot` mapping, including the empty-cart → idle case and
    the discount/tax/total pass-through matching `Sale`'s existing getters exactly.
  - `Receipt` → `.thankYou` mapping.
  - Debounce logic for rapid successive `orderingProvider` changes collapsing to one push.
- **Manual** (dual-monitor, native-window behavior isn't meaningfully unit-testable):
  1. Single monitor: app behaves exactly as before, no second window is created.
  2. Dual monitor at launch: customer window appears on monitor 2, maximized, cashier keeps focus.
  3. Add / remove / change quantity / apply discount / clear cart → customer display updates each
     time, matches cashier totals exactly.
  4. Complete payment → thank-you (with `docNumber`) → auto-idle after 5s.
  5. New Order / Close from receipt screen → customer display returns to idle immediately.
  6. Unplug monitor 2 while running → customer window is torn down; cashier unaffected.
  7. Replug monitor 2 while running → customer window is recreated, correctly reflects whatever the
     current order state is at that moment (not stale).
  8. Close the customer-display window directly (its own window controls, or Alt+F4 while it's
     focused) → cashier keeps accepting input/processing a sale throughout; window is recreated per
     the retry policy. (Note: this is a same-process second window, not a second OS process — there
     is no separate process to kill via Task Manager; closing the window itself is the realistic
     failure to simulate.)
  9. Rapid-fire cart edits (e.g. tapping quantity stepper repeatedly) → no IPC flood, no visible lag
     on the cashier side.

---

## Next step

When you're ready to build this, this spec is the input to `superpowers:writing-plans` for a
bite-sized implementation plan (adding `desktop_multi_window` + promoting `screen_retriever` to a
direct dependency, the native `main.cpp` branch, the `customer_display` feature module, and the
`CustomerDisplayHost`/`CustomerDisplayReceiver` wiring).
