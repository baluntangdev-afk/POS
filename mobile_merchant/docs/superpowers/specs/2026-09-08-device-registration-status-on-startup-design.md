# Device registration status check on app startup

## Problem

On startup the merchant app only checks whether a local `merchant` row exists.
It never confirms with the backend that the device is still an approved,
enrolled device. A pending or deactivated device silently ends up with a dead
order feed and no explanation.

## Goal

On every launch, for an already-registered merchant:

1. Call `POST /auth/token`. **Only if it succeeds**, call `POST /devices/register`.
2. React to the returned device `status`:
   - `approved` → show a success toast, but only when the status just
     transitioned into `approved` this launch.
   - `pending` / `deactivated` / anything else → show a dismissible,
     informational dialog.
3. The live order WebSocket feed connects only when `status == 'approved'`.

## Backend contract

`POST /devices/register` (already wired via `MerchantApi.registerDevice`,
idempotent on `Idempotency-Key: installId`):

- **200** — duplicate matched on install id:
  `{ device_id, status, merchant_id, merchant_name, requested_at, reviewed_at, review_note }`
- **202** — new enrolment:
  `{ device_id, device_secret, status, merchant_name }`

Both carry `device_id` + `status`. `DeviceRegistrationDto` already models every
field and `_assertSuccess` already accepts `{200, 202}` — no DTO changes.

Known statuses: `pending`, `approved`, `deactivated`. Treated forward-compatibly:
`approved` is the only "active" state; every other value routes to the dialog.

## Changes (all under `mobile_merchant/lib/`)

### 1. `core/storage/merchant_device_storage.dart`

- Add `_deviceStatusKey = 'merchant_device_status'`.
- `Future<String?> get deviceStatus`, `Future<void> writeDeviceStatus(String)`.
- Delete the key in `clearForMerchantChange()`.

The stored value is an optimistic cache: it lets an already-approved device
connect its feed immediately on launch, before the network round-trip.

### 2. `features/merchant/domain/entities/device_startup_result.dart` (new)

Plain class (no codegen):

```dart
class DeviceStartupResult {
  const DeviceStartupResult.tokenUnavailable()
      : status = null, justApproved = false;
  const DeviceStartupResult({required this.status, required this.justApproved});

  final String? status;       // null => auth/token failed, register skipped
  final bool justApproved;    // transitioned into approved this launch

  bool get tokenUnavailable => status == null;
  bool get isApproved => status == DeviceStatus.approved;
}

class DeviceStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const deactivated = 'deactivated';
}
```

### 3. `features/merchant/domain/repositories/merchant_repository.dart`

- `activateDevice(String merchantId)` return type `Future<DeviceRegistration>`.
- Add `Future<DeviceRegistration> syncDeviceRegistration()` — re-runs
  fingerprint + `/devices/register` + persist using the **already-stored**
  webhook token. Precondition: a token is present (caller guarantees it by
  calling `refreshToken` first).

### 4. `features/merchant/data/repositories/merchant_repository_impl.dart`

- Extract steps 2–4 of `activateDevice` into
  `Future<DeviceRegistration> _registerAndPersist(String token, String merchantId)`
  which also calls `_storage.writeDeviceStatus(registration.status)` and returns
  the domain object.
- `activateDevice` = mint token + `_registerAndPersist`, returns the result.
- `syncDeviceRegistration` = read stored token (throw `StateError` if missing) +
  `_registerAndPersist` for the stored `registeredMerchantId`.

### 5. `features/merchant/state/merchant_notifier.dart`

- `register(...)` returns `Future<DeviceRegistration>` (still refreshes state).
- New `Future<DeviceStartupResult> syncOnStartup()`:
  1. Read previous `deviceStatus` from storage.
  2. `refreshToken(merchant.merchantId)` inside try/catch. On any exception →
     `DeviceStartupResult.tokenUnavailable()`.
  3. `syncDeviceRegistration()`; `next = registration.status`.
  4. `justApproved = prev != null && prev != approved && next == approved`.
  5. `state = await AsyncValue.guard(build)` then return
     `DeviceStartupResult(status: next, justApproved: justApproved)`.

### 6. `features/merchant/presentation/dialogs/device_status_dialog.dart` (new)

Dismissible `AlertDialog` styled to match `MerchantFormDialog` (surface color,
`radiusLg`, icon chip). Single `FilledButton` "Got it" that pops.

Copy by status:

| status | title | body |
|---|---|---|
| `pending` | Waiting for approval | Your device registration is under review by your merchant admin. You'll get access once it's approved. |
| `deactivated` | Device deactivated | This device's access has been turned off. Contact your merchant admin to restore it. |
| other | Device not active | This device isn't active yet. Contact your merchant admin for help. |

When `reviewNote` is non-null/non-empty, render it under the body in a muted
box.

### 7. `features/dashboard/presentation/screens/dashboard_screen.dart`

`_checkMerchant`:

- `merchant != null` branch:
  ```dart
  final result = await ref.read(merchantProvider.notifier).syncOnStartup();
  if (!mounted) return;
  _handleDeviceStatus(result.status, result.justApproved, reviewNote);
  unawaited(ref.read(ordersFeedNotifierProvider.notifier).checkConnection());
  ```
  (`reviewNote` from the registration — thread it through `DeviceStartupResult`
  as an extra nullable field rather than a separate lookup.)
- `merchant == null` branch: after `register(...)` resolves, feed the returned
  `DeviceRegistration` into `_handleDeviceStatus`. Remove the hardcoded
  "Device registered successfully! You're all set." toast.
- `_handleDeviceStatus(String? status, bool justApproved, String? note)`:
  - `status == null` → return (existing error paths already surface token
    failures).
  - `status == approved` → if `justApproved`, `AppSnackbar.success(context,
    "Device approved — you're all set.")`; else nothing.
  - else → `showDialog(barrierDismissible: true, builder: DeviceStatusDialog(...))`.
- Guard against double-invocation with the existing `_registrationShown`-style
  latch (rename to `_startupHandled`).

### 8. `features/orders/state/orders_feed_notifier.dart`

Both `build()` and `checkConnection()` already gate on webhook-token presence.
Add, immediately after that check:

```dart
final status = await getIt<MerchantDeviceStorage>().deviceStatus;
if (status != DeviceStatus.approved) {
  // build(): return disconnected
  // checkConnection(): _teardown(); state = disconnected; return;
}
```

Reconciliation: cached `approved` lets the feed connect immediately on launch;
`syncOnStartup` + the subsequent `checkConnection()` then correct a device whose
status changed server-side (a newly-deactivated device connects briefly, then
drops when the dialog appears).

## Non-goals

- No dedicated `GET /devices/me` endpoint (doesn't exist; `/devices/register`
  is idempotent and serves the purpose).
- No retry / polling UI in the dialog — user dismisses, next launch re-checks.
- No new tests (project convention). Verified with `dart analyze`.
- No `build_runner` run — no annotated classes added.
