# Launch auth chain: auth/token → devices/register → devices/token → WS

## Problem

On every launch the merchant app must re-establish its live-order WebSocket
connection through a fixed four-step auth chain. Today the steps exist but are
split across two Riverpod notifiers that run concurrently, so ordering is not
guaranteed, and two of the calls do not behave as required:

- `POST /devices/token` is served from a cache and is often skipped entirely.
- `POST /devices/token` is sent with **no `Authorization` header**.
- `OrdersFeedNotifier.build()` races `MerchantNotifier.syncOnStartup()` — the
  feed can call `/devices/token` before `/devices/register` has resolved.
- The `device_id` / `device_secret` used for `/devices/token` are read from
  secure storage rather than from the fresh `/devices/register` response.

## Goal

On **every launch**, for an already-registered merchant, run exactly this chain
in order:

```
1. POST /auth/token         body { webhook_secret, merchant_id }
     └─ 200 → { token: W, merchant_id, merchant_name, exp }

2. POST /devices/register    headers Authorization: Bearer W
                             headers Idempotency-Key: <installId>
                             body   <device fingerprint>
     └─ 200/202 → { device_id, device_secret?, status, merchant_name, ... }

     if status != 'approved'  → STOP. Show DeviceStatusDialog. Feed stays
                                disconnected. No /devices/token, no WS.

3. POST /devices/token       headers Authorization: Bearer W
                             body   { device_id, device_secret }
                             (device_id / device_secret taken from the step-2
                              response; see "Credential source" below)
     └─ 200 → { device_id, merchant_id, token: D, exp }

4. WS  <wsBase>/ws?merchant_id=<id>   headers Authorization: Bearer D
```

Steps 1–3 make a real HTTP call on every launch. Step 3 is **not** cached
across launches.

## Credential source

`device_id` and `device_secret` for step 3 come from the **step-2 response**,
and only when `status == 'approved'`.

Observed approved response shape:

```json
{
  "device_id": "dev_22104594db1166f8601bcc889e9787e202a947c547b6045c",
  "device_secret": "dsk_01fc24eae4a76579dea66387090df7ae4b87ed629016426c",
  "status": "approved",
  "merchant_name": "Uncle Brew - IT PARK"
}
```

`DeviceRegistrationDto` / `DeviceRegistration` already model `deviceSecret` as
nullable — no DTO changes.

**Fallback:** if `status == 'approved'` but the response omits `device_secret`
(a `200` duplicate match may not echo it), fall back to the secret already in
`MerchantDeviceStorage` (persisted from a prior `202`). `/devices/token` still
fires. If neither source has a secret, the mint throws and the feed enters its
normal reconnect/backoff path — no crash, no dialog.

## Approach

Introduce a **`deviceStartupProvider`** (`FutureProvider<DeviceStartupResult>`)
that owns steps 1–2 and runs once per launch (memoized by Riverpod). Both the
dashboard and `OrdersFeedNotifier.build()` `await` it, so the feed physically
cannot reach step 3 until `/devices/register` has resolved. This replaces the
imperative `ref.read(merchantProvider.notifier).syncOnStartup()` call in the
dashboard.

Rejected alternative: removing `unawaited(_connect())` from
`OrdersFeedNotifier.build()` and letting only the dashboard's post-sync
`checkConnection()` drive the connect. Smaller diff, but any other reader of the
feed provider would then get a provider that never connects — fragile.

## Changes (all under `mobile_merchant/lib/`)

### 1. `features/merchant/domain/entities/device_startup_result.dart`

Add two nullable fields to the existing plain class:

```dart
class DeviceStartupResult {
  const DeviceStartupResult.tokenUnavailable()
      : status = null,
        justApproved = false,
        reviewNote = null,
        deviceId = null,
        deviceSecret = null;

  const DeviceStartupResult({
    required this.status,
    required this.justApproved,
    this.reviewNote,
    this.deviceId,
    this.deviceSecret,
  });

  final String? status;
  final bool justApproved;
  final String? reviewNote;
  final String? deviceId;      // from /devices/register, approved only
  final String? deviceSecret;  // from /devices/register, approved only; may be null

  bool get tokenUnavailable => status == null;
  bool get isApproved => status == DeviceStatus.approved;
}
```

`deviceId` / `deviceSecret` are populated only when `status == 'approved'`;
otherwise left null.

No `build_runner` — `DeviceStartupResult` is a hand-written class, not an
annotated one.

### 2. `features/merchant/state/merchant_notifier.dart`

- `syncOnStartup()`: after `syncDeviceRegistration()` resolves, thread
  `registration.deviceId` and `registration.deviceSecret` into the returned
  `DeviceStartupResult` **only when `next == DeviceStatus.approved`**.
- Add the provider:

  ```dart
  final deviceStartupProvider = FutureProvider<DeviceStartupResult>((ref) async {
    // ref.read (not watch): syncOnStartup mutates merchantProvider state, and
    // watching merchantProvider.future here would re-trigger this provider.
    final merchant = await ref.read(merchantProvider.future);
    if (merchant == null) return const DeviceStartupResult.tokenUnavailable();
    return ref.read(merchantProvider.notifier).syncOnStartup();
  });
  ```

`save()` (merchant-change path) gains `ref.invalidate(deviceStartupProvider)`
inside the `existing.merchantId != merchantId` block, so a merchant switch
re-runs the chain on the next feed build.

`syncOnStartup()`'s existing behaviour is otherwise unchanged: read previous
cached status, `refreshToken()` (step 1) in try/catch → `tokenUnavailable` on
failure, `syncDeviceRegistration()` (step 2) in try/catch → `tokenUnavailable`
on failure, compute `justApproved`, rebuild `merchantProvider`.

`_registerAndPersist` in `merchant_repository_impl.dart` already persists the
webhook token, `deviceId`, `deviceSecret` (when present), `registeredMerchantId`
and `deviceStatus` — no change needed there.

### 3. `features/dashboard/presentation/screens/dashboard_screen.dart`

`_checkMerchant`, `merchant != null` branch:

```dart
final result = await ref.read(deviceStartupProvider.future);
if (!mounted) return;
_handleDeviceStatus(result.status, result.justApproved, result.reviewNote);
unawaited(ref.read(ordersFeedNotifierProvider.notifier).checkConnection());
return;
```

`_handleDeviceStatus` and the `merchant == null` registration branch are
unchanged. The `_startupHandled` latch stays.

### 4. `features/merchant/data/merchant_api.dart`

```dart
Future<DeviceTokenDto> fetchDeviceToken({
  required String deviceId,
  required String deviceSecret,
  required String token,          // webhook JWT (W) from /auth/token
}) async {
  final response = await _apiClient.dio.post<dynamic>(
    ApiEndpoints.devicesToken,
    data: {'device_id': deviceId, 'device_secret': deviceSecret},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  _assertSuccess(response, const {200});
  return DeviceTokenDto.fromJson((response.data as Map).cast<String, dynamic>());
}
```

### 5. `features/orders/data/repositories/device_token_repository.dart`

- Replace `ensureToken()` (cache-hit early return) with an unconditional
  `mint()`:

  ```dart
  Future<String> mint({
    required String merchantId,
    required String webhookToken,
    required String deviceId,
    String? deviceSecret,
  }) async {
    final secret = (deviceSecret != null && deviceSecret.isNotEmpty)
        ? deviceSecret
        : await _storage.deviceSecret;
    if (deviceId.isEmpty || secret == null || secret.isEmpty) {
      throw Exception('Device credentials unavailable for /devices/token');
    }
    final dto = await _api.fetchDeviceToken(
      deviceId: deviceId,
      deviceSecret: secret,
      token: webhookToken,
    );
    await _storage.writeDeviceWsToken(dto.token, dto.exp, dto.merchantId);
    return dto.token;
  }
  ```

- Keep `invalidate()` (clears the cached WS token on a 401/403 handshake
  rejection). The cache still exists — it is read by nothing on the launch path
  now, but `writeDeviceWsToken` keeps it fresh for any future consumer and for
  parity with `mobile/`.
- `refreshToken()` is removed / folded into `mint()`.

### 6. `features/orders/state/orders_feed_notifier.dart`

- `build()` (`_disconnected` below is shorthand for
  `const OrdersFeedState(connection: OrdersFeedConnection.disconnected)`):

  ```dart
  final merchant = await ref.watch(merchantProvider.future);
  if (merchant == null) return _disconnected;

  final startup = await ref.watch(deviceStartupProvider.future);
  if (!startup.isApproved) return _disconnected;

  _startupDeviceId = startup.deviceId;
  _startupDeviceSecret = startup.deviceSecret;
  unawaited(_connect(merchant.merchantId));
  return OrdersFeedState(connection: connecting, merchantId: merchant.merchantId);
  ```

  The old standalone `storage.token` presence check and `storage.deviceStatus`
  check are subsumed by `startup.isApproved` (an approved result means step 1
  succeeded and step 2 returned `approved`). Keep a defensive `storage.token`
  read only if `startup.deviceId` is null.

- `_connect()`: between `_ensureWebhookToken` and the handshake, replace
  `_deviceTokenRepo.ensureToken(merchantId)` with:

  ```dart
  final webhookToken = await getIt<MerchantDeviceStorage>().token;
  if (webhookToken == null || webhookToken.isEmpty) {
    throw StateError('no webhook token for /devices/token');
  }
  final deviceToken = await _deviceTokenRepo.mint(
    merchantId: merchantId,
    webhookToken: webhookToken,
    deviceId: _startupDeviceId ?? (await getIt<MerchantDeviceStorage>().deviceId ?? ''),
    deviceSecret: _startupDeviceSecret,
  );
  ```

  `_ensureWebhookToken` stays as-is: on the first connect of a launch the
  webhook token was just minted by step 1, so its "still valid for >1 min"
  check skips the call; on a later in-session reconnect it refreshes an expired
  token before `mint()` runs.

- `checkConnection()`: unchanged in structure. Its `deviceStatus` gate still
  works (an affirmatively-cached non-approved status tears the socket down).
  Because `build()` now blocks on `deviceStartupProvider`, the dashboard's
  `checkConnection()` call runs after step 2 and is normally a no-op (a connect
  is already in flight).

- `_teardown()`: also clear `_startupDeviceId` / `_startupDeviceSecret`.

## Ordering guarantee

`deviceStartupProvider` is awaited by both `OrdersFeedNotifier.build()` and the
dashboard. Riverpod computes it once and hands the same `Future` to both
awaiters. `build()` therefore cannot call `_connect()` (and thus `mint()` /
step 3) until steps 1–2 have resolved. A merchant change during the session
calls `ref.invalidate(deviceStartupProvider)` from `MerchantNotifier.save()`,
which re-runs the whole chain on the next feed build.

## Error handling

| Failure | Result |
|---|---|
| `/auth/token` throws | `DeviceStartupResult.tokenUnavailable()`. Dashboard silent. Feed → disconnected. |
| `/devices/register` throws | `DeviceStartupResult.tokenUnavailable()`. Same as above. |
| `status` present but not `approved` | Dashboard shows `DeviceStatusDialog`. Feed → disconnected. No step 3. |
| `approved`, no `device_secret` anywhere | `mint()` throws inside `_connect()` → caught → `reconnecting` + backoff. No dialog. |
| `/devices/token` 401/403 | `_connect` catch → `_deviceTokenRepo.invalidate()` → `reconnecting` + backoff. |
| WS handshake timeout (10s) | `reconnecting` + exponential backoff (1s → 30s). |

## Non-goals

- No backend changes.
- No caching of the `/devices/token` result across launches (in-session
  reconnects re-mint, which is acceptable and handles expiry).
- No new `GET /devices/me` endpoint.
- No retry/polling UI in `DeviceStatusDialog`.
- No new tests (project convention). Verified with `dart analyze`.
- No `build_runner` run — no annotated classes change.
