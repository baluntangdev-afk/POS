# App-wide internet + socket connectivity status (design)

## Current state

- `kiosk/lib/features/orders/state/orders_feed_notifier.dart` (`OrdersFeedNotifier`) owns the only
  live network-connection state in the app today: `OrdersFeedState.connection`, an
  `OrdersFeedConnection` enum (`disconnected`, `connecting`, `connected`, `reconnecting`) tracking
  the WebSocket session to the webhook-receiver (`OrdersLiveFeedRepository` /
  `orders_live_feed_repository.dart`). It reconnects with exponential backoff
  (`_initialBackoff` 1s → `_maxBackoff` 30s) whenever the socket drops, entirely independent of
  whether the device actually has a working network interface — a fully offline device just cycles
  through backoff forever with no distinction from "socket server is down but internet is fine."
- The only visual surface for this state today is `_ConnectionBanner` in
  `kiosk/lib/features/orders/view/orders_screen.dart` — a banner shown at the top of the Orders
  screen body only, hidden when `connection == connected`. No other screen shows any connectivity
  status.
- `kiosk/lib/app.dart` already hosts the one existing app-wide (screen-independent) reactive
  surface: it `ref.watch`es `ordersFeedNotifierProvider` directly (keeping the socket alive
  app-wide via `ref.keepAlive()` inside the notifier) and `ref.listen`s it to fire toasts
  (`scaffoldMessengerKey`) on new orders and on socket reconnect — this already proves the pattern
  of app-wide reactions to this provider without needing a screen to be mounted.
- There is no device-level (OS network interface) connectivity detection anywhere in the codebase.
  `connectivity_plus` is not a dependency.
- The kiosk has no shared top-level app-bar/header widget wrapping every screen — `BrandHeader` is
  instantiated per-screen (e.g. `orders_screen.dart:31`), not globally. The only global insertion
  point that reaches every screen is `MaterialApp.router`'s `builder` callback in `app.dart`, which
  already wraps every routed screen in `OnScreenKeyboardScope` + `GlobalUnfocusOnTapOutside`.

## Goals

1. Detect whether the device has a live network interface (WiFi/Ethernet up), independent of
   whether the orders WebSocket happens to be connected.
2. Show one combined, app-wide status banner — visible on every screen, not just Orders — that
   distinguishes "device is offline" from "device is online but the orders socket isn't connected"
   from "everything's fine" (hidden).
3. When the device regains connectivity after being offline, the orders socket should retry
   immediately rather than sitting out whatever backoff delay was in progress.
4. No duplicate banners — remove the Orders-screen-local banner now that the app-wide one
   supersedes it.

## Non-goals (this pass)

- No toast/snackbar for connectivity or socket-state transitions beyond what already exists
  (`_onOrdersFeedStateChange` in `app.dart` already toasts once on socket reconnect — left as is).
  This pass is banner-only for the new device-connectivity signal, per your answer during design.
- No true internet-reachability probing (ping/HTTP HEAD to a known host). `connectivity_plus`
  reports OS-level interface state only — "WiFi connected, router has no internet" will read as
  online. Out of scope per your answer during design.
- No changes to backoff timing/limits themselves, other than the one immediate-retry trigger on
  offline→online transition described above.
- No non-Windows platform work; `connectivity_plus` is cross-platform but this pass is verified on
  Windows only, matching how the rest of the kiosk is targeted.

---

## Approach chosen: `connectivity_plus` stream provider + app-wide overlay banner in `app.dart`

Two placements for the banner were considered:

1. **App-wide overlay via `MaterialApp.router`'s `builder`, stacked above `child` (chosen).**
   Reuses the one existing global insertion point already used for `OnScreenKeyboardScope` /
   `GlobalUnfocusOnTapOutside`. No per-screen wiring, no risk of a screen forgetting to include it.
2. **Add it to every screen's own header/scaffold individually.** Rejected — the app has no shared
   header widget (`BrandHeader` is instantiated per-screen, not composed globally), so this would
   mean touching every screen file and staying disciplined about new screens including it. Strictly
   worse for the "every screen" requirement than the single `builder`-level insertion.

## Components

### 1. `kiosk/lib/core/connectivity/connectivity_status_provider.dart` (new)

A `StreamProvider<bool>` named `isOnlineProvider`, `true` meaning "device has at least one active
network interface" per `connectivity_plus`'s `Connectivity().onConnectivityChanged` stream (a
`List<ConnectivityResult>` in the installed major version — `true` iff the list contains anything
other than `ConnectivityResult.none`). The stream is seeded with one `Connectivity().checkConnectivity()`
call so the first emission isn't "unknown" while waiting for the first OS change event.

This lives under `lib/core/` (alongside the existing `lib/core/database/`) rather than under
`lib/features/` — it's a device-level capability with no domain/feature ownership, matching how
`core/database` already holds cross-feature infrastructure.

### 2. `kiosk/lib/widgets/connectivity_status_banner.dart` (new)

A `ConsumerWidget`, `ConnectivityStatusBanner`, that watches both `isOnlineProvider` and
`ordersFeedNotifierProvider.select((s) => s.value?.connection)`, and renders a single banner
(visually modeled on the existing `_ConnectionBanner` — same dot + label row style, `POSColors`/
`ColorSet` tokens, `context.responsive` paddings) with this priority:

| Device online? | Socket state | Banner |
|---|---|---|
| No | (any) | "No internet connection" — `ColorSet.danger` |
| Yes | `connecting` | "Connecting…" — `ColorSet.warning` |
| Yes | `reconnecting` | "Reconnecting…" — `ColorSet.warning` |
| Yes | `disconnected` | "Not connected" — `POSColors.textTertiary` |
| Yes | `connected` | *(hidden — `SizedBox.shrink()`)* |

Offline takes priority over whatever the socket enum currently says, since a dropped interface will
also eventually surface as `reconnecting`/`disconnected` but with a less specific message.

### 3. Wire into `kiosk/lib/app.dart`

Inside `MaterialApp.router`'s `builder`, wrap the existing `content` in a `Column`
(`ConnectivityStatusBanner` above, `Expanded(child: content)` below) rather than a floating
`Stack`/`Positioned` overlay — the banner should push screen content down when visible, matching
how `_ConnectionBanner` already behaves today inside `orders_screen.dart`'s own `Column`, not float
over it and risk obscuring touch targets at the top of a screen (e.g. `BrandHeader`'s Back button).

### 4. Remove the local banner

Delete `_ConnectionBanner` and its usage from `kiosk/lib/features/orders/view/orders_screen.dart`
(`orders_screen.dart:32,42-80`) — the app-wide banner now covers this screen too, and showing both
would duplicate the same information.

### 5. Immediate reconnect on offline→online transition

`OrdersFeedNotifier.build()` already `ref.watch`es `loginStateProvider`. Add a
`ref.listen(isOnlineProvider, ...)` (also inside `build()`, alongside the existing `ref.onDispose`)
that, on a transition from `false`/`AsyncLoading` to `true` while `state.value?.connection` is
`reconnecting` or `disconnected`, cancels the pending `_retryTimer` and calls `_connect()`
immediately — the same effect `_scheduleReconnect` would eventually produce, just without waiting
out the current backoff. This does not touch backoff math itself; a subsequent drop still starts
backoff fresh from wherever `_backoff`'s state was.

## Dependency

Add `connectivity_plus: ^6.1.0` to `kiosk/pubspec.yaml` (latest major at time of writing). Plain
`bool`/enum data — no `@MappableClass`, so no `build_runner` codegen is required for this package
itself. `flutter pub get` only.

## Error handling

- `isOnlineProvider`'s stream never throws under normal operation (`connectivity_plus` reports
  interface state, not reachability, so there's no network call to fail); if the platform channel
  itself errors, the `StreamProvider` surfaces `AsyncError`, and `ConnectivityStatusBanner` treats
  any non-`AsyncData(true)` state (loading or error) the same as "not confirmed online" — i.e. it
  falls through to the offline banner rather than assuming online. This errs toward showing a
  banner rather than silently hiding a real problem.

## Testing

- Manual verification only (per repo convention — no existing widget/unit tests cover
  `orders_feed_notifier.dart` or `orders_screen.dart` today): disable/enable the network adapter (or
  pull the Ethernet cable) while the app is running and confirm the banner shows "No internet
  connection" immediately, then confirm it clears and the socket reconnects promptly (not after a
  30s backoff wait) once connectivity is restored. Separately verify the "online but socket down"
  states by pointing `BACKEND_API_BASE_URL`'s WS endpoint at an unreachable host with the network
  adapter left up.
- `dart analyze` must be clean after the change (this repo's mobile/kiosk verification bar per
  existing convention — no backend involvement needed for this change).
