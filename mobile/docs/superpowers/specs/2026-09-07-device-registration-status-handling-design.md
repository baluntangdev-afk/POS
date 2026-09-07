# Device registration status handling — design

**Date:** 2026-09-07
**Scope:** `mobile/` only (Flutter merchant kiosk app)

## Problem

`POST /devices/register` returns a success payload like:

```json
{
  "device_id": "dev_a1984003b2665dbfb86afa704661bba761fd4b5e43eccc52",
  "device_secret": "dsk_a1f28bb5bed799f486eb8119452d8b635af7d2b5f21878ec",
  "status": "approved",
  "merchant_name": "Uncle Brew - IT PARK"
}
```

Two gaps today:

1. `DeviceRegistrationDto` has no `merchant_name` field, so the resolved merchant
   name from the register response is dropped.
2. `handleMerchantDeviceOutcome` always shows a "Device Pending Approval" dialog
   regardless of the real `status`. There is no persistent status indicator on
   the Store Information screen.

The device registration status can be `pending`, `approved`, `deactivated`,
`rejected`, or any future/unrecognised string. The app must show an appropriate
message for `pending`, `approved`, and `deactivated` (with `rejected` treated the
same as `deactivated`), plus a generic fallback for anything else.

## Non-goals

- No change to the live-orders socket / feed behaviour when a device is
  `deactivated` — the status is surfaced to the user but the socket is left
  alone.
- No new backend endpoint. Status refresh reuses the idempotent
  `POST /devices/register`.

## Design

### 1. DTO — `lib/data/backend_api/schemas/device_registration_dto.dart`

Add:

```dart
/// Human-readable merchant/store name the backend resolved for this device,
/// when it sent one.
final String? merchantName;
```

Keyed `merchant_name` (snake-case class style already handles this). Regenerate
`device_registration_dto.mapper.dart` with build_runner.

### 2. Persistence — `lib/data/secure_storage/sources/merchant_device_storage.dart`

Add two keys, both cleared by `clear()` (they describe the approval, not the
install):

- `merchant_device_status` — last known status string
- `merchant_device_merchant_name` — last known merchant name

New members:

```dart
Future<String?> get lastStatus;
Future<void> writeLastStatus(String status);
Future<String?> get merchantName;
Future<void> writeMerchantName(String name);
```

`clear()` deletes both new keys alongside the existing three.

### 3. Repository — `lib/features/live_orders/repositories/merchant_device_repository.dart`

In `MerchantDeviceRepositoryImpl.registerDevice`, after the API call and the
existing writes:

```dart
await _storage.writeLastStatus(registration.status);
final merchantName = registration.merchantName?.trim() ?? '';
if (merchantName.isNotEmpty) {
  await _storage.writeMerchantName(merchantName);
}
```

Add a matching `Future<String?> lastKnownStatus()` / `lastKnownMerchantName()`
pair to the abstract `MerchantDeviceRepository` and impl, delegating to storage,
for the notifier to hydrate from.

### 4. State — `lib/features/live_orders/entities/merchant_device_state.dart`

Add fields:

```dart
final String? persistedStatus;
final String? persistedMerchantName;
```

Wire them through the constructor and `copyWith`. Replace the `status` getter and
add a `merchantName` getter:

```dart
String? get status => registration?.status ?? persistedStatus;
String? get merchantName => registration?.merchantName ?? persistedMerchantName;
```

### 5. Notifier — `lib/features/live_orders/state/merchant_device_notifier.dart`

- `build()` also reads `lastKnownStatus()` / `lastKnownMerchantName()` and seeds
  `persistedStatus` / `persistedMerchantName`.
- Every `state = AsyncData(MerchantDeviceState(...))` that currently carries
  `deviceId` / `registeredStoreId` also carries the persisted fields so a later
  failure/among-flight rebuild does not wipe the last known status.
- On a successful `register(...)`, set `persistedStatus` / `persistedMerchantName`
  from the fresh `registration` so the getters stay consistent before the next
  `build()`.
- New method:

```dart
/// Re-runs POST /devices/register for the already-registered store to pull
/// the current approval status. Idempotent: the Idempotency-Key is the stable
/// install id, so the backend replays the current record. No-op when the
/// device is not registered yet or has no stored store id.
Future<void> refreshStatus() async { ... }
```

It loads `future`, bails if `!isRegistered` or `registeredStoreId` is
null/empty, then calls the same `deviceIdentityProvider.describe(...)` +
`register(request, storeId: ...)` path used by `registerIfNeeded`, using the
persisted merchant name (falling back to `'POS Device'`) as the device name.

### 6. Apply `merchant_name` — `lib/features/settings/state/store_info_notifier.dart`

In `_provisionForStore`, after `registerIfNeeded(...)` completes:

```dart
final registration =
    ref.read(merchantDeviceNotifierProvider).value?.registration;
final registeredName = registration?.merchantName?.trim() ?? '';
if (registeredName.isNotEmpty) {
  await applyMerchantName(registeredName);
}
```

This keeps the merchant-device layer unaware of store info (no circular
provider dependency). `applyMerchantName` already overwrites both Store Name and
Terminal Name and is a no-op when the value is unchanged, so a second call after
the `/auth/token` one is cheap.

### 7. Status card — new `lib/features/live_orders/view/device_registration_status_card.dart`

`DeviceRegistrationStatusCard extends ConsumerWidget`. Watches
`merchantDeviceNotifierProvider`.

- `state.value?.deviceId == null` → `SizedBox.shrink()`.
- Otherwise a rounded card (match `SectionCard` padding / radius) with an accent
  stripe + leading icon chosen by `_StatusVisual.of(status)`:

| status (lower-cased) | color | icon | headline |
|---|---|---|---|
| `approved` | `AppColors.success` | `Icons.check_circle_rounded` | Device approved |
| `pending` | `AppColors.warning` | `Icons.hourglass_top_rounded` | Waiting for approval |
| `deactivated`, `rejected` | `AppColors.error` | `Icons.block_rounded` | Device deactivated |
| anything else / null | `AppColors.primary` | `Icons.info_rounded` | Status: `<raw>` |

- Body line: one sentence matching the dialog copy (see §8), merchant name
  interpolated when `state.merchantName` is non-empty.
- Trailing: a "Check status" `TextButton` calling
  `ref.read(merchantDeviceNotifierProvider.notifier).refreshStatus()`; shows a
  16px `CircularProgressIndicator` and is disabled while
  `state.value?.isRegistering == true`.

Rendered as the first child of the `ListView` in `_StoreInfoForm.build`
(`store_info_screen.dart`), above the "Basic Info" `SectionCard`, with a
`Gap(AppSpacing.lg)` after it.

### 8. Dialog on change — `lib/features/live_orders/view/device_registration_prompt.dart`

Replace the module-level `_promptedDeviceId` guard with:

```dart
String? _shownStatusKey; // '<deviceId>|<status>'
```

In `handleMerchantDeviceOutcome`, before the error branch:

```dart
final status = next.status?.trim().toLowerCase();
final deviceId = next.registration?.deviceId ?? next.deviceId;
if (status != null && status.isNotEmpty && deviceId != null) {
  final key = '$deviceId|$status';
  if (key != _shownStatusKey) {
    _shownStatusKey = key;
    _shownError = null;
    final copy = _statusDialogCopy(status, next.merchantName);
    unawaited(showSetupPromptDialog(context, ...copy));
    return;
  }
}
```

`_statusDialogCopy(status, merchantName)` returns `(SetupPromptType, title,
message)`:

- **pending** → `info` · "Device Pending Approval" · "This device was submitted
  to `{merchant}` and is waiting for approval. You can keep using the POS in the
  meantime — live orders begin once it's approved."
- **approved** → `info` · "Device Approved" · "This device is approved for
  `{merchant}`. Live orders are now enabled."
- **deactivated** / **rejected** → `warning` · "Device Deactivated" · "This
  device's access to `{merchant}` has been turned off. Live orders are paused.
  Contact your merchant administrator to restore access."
- **fallback** → `info` · "Device Status" · "This device's registration status
  is '`{status}`'."

`{merchant}` is replaced with `next.merchantName` when non-empty, otherwise
"your merchant account". Primary button "Got it" for info, "OK" for warning.

The existing error branch (`next.error`) is unchanged and still runs when there
is no status to show.

`dashboard_screen.dart` already calls `handleMerchantDeviceOutcome` — it picks up
the new behaviour for free.

## Data flow

```
Store ID changed
  → StoreInfoNotifier._provisionForStore
      → _refreshToken (POST /auth/token) → applyMerchantName(auth merchant_name)
      → merchantDeviceNotifier.registerIfNeeded
          → repository.registerDevice (POST /devices/register)
              → secure storage: device_id, device_secret, status, merchant_name
          → state.registration = DeviceRegistrationDto (status, merchantName)
      → applyMerchantName(registration.merchantName)   // new

App restart
  → merchantDeviceNotifier.build
      → hydrate deviceId, registeredStoreId, persistedStatus, persistedMerchantName

Store Info screen
  → ref.listen(merchantDeviceNotifierProvider) → handleMerchantDeviceOutcome  // dialog on (deviceId,status) change
  → DeviceRegistrationStatusCard watches merchantDeviceNotifierProvider        // persistent card
      → "Check status" → notifier.refreshStatus() → POST /devices/register (idempotent replay)
```

## Error handling

- `refreshStatus()` reuses `register(...)`, which already maps failures to
  `DeviceRegistrationError` and sets `state.error` / `errorMessage`. The existing
  error branch of `handleMerchantDeviceOutcome` shows those. A `pending`-approval
  rejection during refresh is normal and surfaces as the mapped copy.
- Unrecognised status strings never throw — they hit the fallback card visual and
  fallback dialog copy.
- Missing `merchant_name` → card/dialog use "your merchant account"; no write to
  `merchant_device_merchant_name`.

## Verification

From `mobile/`:

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

No new test files (per project convention); `dart analyze` must be clean.

## Files touched

| File | Change |
|---|---|
| `lib/data/backend_api/schemas/device_registration_dto.dart` | add `merchantName` |
| `lib/data/backend_api/schemas/device_registration_dto.mapper.dart` | regenerated |
| `lib/data/secure_storage/sources/merchant_device_storage.dart` | 2 new keys + accessors, `clear()` |
| `lib/features/live_orders/repositories/merchant_device_repository.dart` | persist status/name; expose last-known getters |
| `lib/features/live_orders/entities/merchant_device_state.dart` | persisted fields + getters |
| `lib/features/live_orders/state/merchant_device_notifier.dart` | hydrate persisted fields; `refreshStatus()` |
| `lib/features/settings/state/store_info_notifier.dart` | apply `registration.merchantName` |
| `lib/features/live_orders/view/device_registration_prompt.dart` | status-aware dialog |
| `lib/features/live_orders/view/device_registration_status_card.dart` | **new** widget |
| `lib/features/settings/view/store_info_screen.dart` | mount the card |
