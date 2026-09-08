# Launch Auth Chain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every app launch run a strict `POST /auth/token` → `POST /devices/register` → `POST /devices/token` → WebSocket chain, with the device-token bearer coming from `/auth/token` and the device credentials coming from the `/devices/register` response.

**Architecture:** A new `deviceStartupProvider` (`FutureProvider<DeviceStartupResult>`) owns steps 1–2 and is `await`ed by both the dashboard and `OrdersFeedNotifier.build()`, which guarantees registration resolves before the feed mints a device token. `DeviceTokenRepository` drops its cross-launch cache and mints on every connect. `MerchantApi.fetchDeviceToken` gains the `Authorization: Bearer` header.

**Tech Stack:** Flutter, `hooks_riverpod` / `flutter_riverpod` (plain providers, not `@riverpod` codegen), `dio`, `freezed` (entities only — no new annotated classes here), `injectable`/`get_it`.

**Project conventions (from CLAUDE.md + memory):**
- **No new test files.** Verify every task with `dart analyze` only.
- **No git commits.** CLAUDE.md: "NEVER create git commits unless I explicitly ask." Each task ends at a passing `dart analyze`; do not stage or commit.
- Keep all changes under `mobile_merchant/`. Do not touch `be/`, `kiosk/`, or `mobile/`.
- No `build_runner` run — no annotated classes are added or changed.

**Spec:** `docs/superpowers/specs/2026-09-08-launch-auth-chain-design.md`

**Run all commands from** `C:\Users\Jufiel\Documents\POS_ENTERPRISE\POS_KIOSK\mobile_merchant`.

---

## File Structure

| File | Responsibility | Change |
|---|---|---|
| `lib/features/merchant/domain/entities/device_startup_result.dart` | Result of the once-per-launch device check | Add `deviceId` / `deviceSecret` fields |
| `lib/features/merchant/state/merchant_notifier.dart` | Merchant `AsyncNotifier` + startup orchestration | Thread creds into result; add `deviceStartupProvider`; invalidate it on merchant change |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Dashboard startup handling | Read `deviceStartupProvider` instead of calling `syncOnStartup()` directly |
| `lib/features/merchant/data/merchant_api.dart` | HTTP data source for auth/device endpoints | `fetchDeviceToken` gains `token` param + bearer header |
| `lib/features/orders/data/repositories/device_token_repository.dart` | Mints the `/devices/token` WS bearer JWT | Replace cached `ensureToken`/`refreshToken` with unconditional `mint` |
| `lib/features/orders/state/orders_feed_notifier.dart` | Live-orders WS feed lifecycle | Gate `build()` on `deviceStartupProvider`; feed creds into `mint()` |

---

## Task 1: Add credential fields to `DeviceStartupResult`

**Files:**
- Modify: `lib/features/merchant/domain/entities/device_startup_result.dart`

- [ ] **Step 1: Replace the `DeviceStartupResult` class body**

Replace the entire class (keep the `DeviceStatus` class above it untouched) with:

```dart
/// Outcome of the once-per-launch device check (see
/// `MerchantNotifier.syncOnStartup`).
class DeviceStartupResult {
  const DeviceStartupResult({
    required this.status,
    required this.justApproved,
    this.reviewNote,
    this.deviceId,
    this.deviceSecret,
  });

  /// Token minting (`POST /auth/token`) failed, so `/devices/register` was
  /// never called. The existing error paths surface the failure.
  const DeviceStartupResult.tokenUnavailable()
      : status = null,
        justApproved = false,
        reviewNote = null,
        deviceId = null,
        deviceSecret = null;

  /// `null` when [tokenUnavailable]; otherwise the raw backend status string.
  final String? status;

  /// The status transitioned into `approved` on this launch (was previously
  /// stored as something other than `approved`).
  final bool justApproved;

  /// Optional admin review note, shown in the status dialog when present.
  final String? reviewNote;

  /// `device_id` from the `/devices/register` response. Set only when
  /// [isApproved]; used as the `POST /devices/token` request body.
  final String? deviceId;

  /// `device_secret` from the `/devices/register` response. Set only when
  /// [isApproved], and may still be null (a `200` duplicate match need not
  /// echo it) — the caller then falls back to the stored secret.
  final String? deviceSecret;

  bool get tokenUnavailable => status == null;

  bool get isApproved => status == DeviceStatus.approved;
}
```

- [ ] **Step 2: Verify analysis is clean**

Run: `dart analyze lib/features/merchant/domain/entities/device_startup_result.dart`
Expected: `No issues found!`

---

## Task 2: Thread creds through `syncOnStartup` + add `deviceStartupProvider`

**Files:**
- Modify: `lib/features/merchant/state/merchant_notifier.dart`

- [ ] **Step 1: Populate `deviceId` / `deviceSecret` in the `syncOnStartup` return**

In `syncOnStartup()`, replace this block:

```dart
    final next = registration.status;
    final justApproved = prev != null &&
        prev != DeviceStatus.approved &&
        next == DeviceStatus.approved;

    state = await AsyncValue.guard(build);

    return DeviceStartupResult(
      status: next,
      justApproved: justApproved,
      reviewNote: registration.reviewNote,
    );
```

with:

```dart
    final next = registration.status;
    final justApproved = prev != null &&
        prev != DeviceStatus.approved &&
        next == DeviceStatus.approved;

    state = await AsyncValue.guard(build);

    final approved = next == DeviceStatus.approved;
    return DeviceStartupResult(
      status: next,
      justApproved: justApproved,
      reviewNote: registration.reviewNote,
      deviceId: approved ? registration.deviceId : null,
      deviceSecret: approved ? registration.deviceSecret : null,
    );
```

- [ ] **Step 2: Invalidate `deviceStartupProvider` on a merchant change**

In `save()`, replace this block:

```dart
    if (existing.merchantId != merchantId) {
      await repo.clearDeviceCredentials();
      await repo.activateDevice(merchantId);
    }

    state = await AsyncValue.guard(build);
```

with:

```dart
    if (existing.merchantId != merchantId) {
      await repo.clearDeviceCredentials();
      await repo.activateDevice(merchantId);
      ref.invalidate(deviceStartupProvider);
    }

    state = await AsyncValue.guard(build);
```

- [ ] **Step 3: Add the provider**

At the end of the file, immediately after the existing `merchantProvider` declaration, add:

```dart
/// Runs the once-per-launch device auth chain (`POST /auth/token` →
/// `POST /devices/register`) exactly once and memoizes the result. Awaited by
/// both the dashboard and `OrdersFeedNotifier.build()`, so the live feed can
/// never mint `/devices/token` before registration has resolved.
final deviceStartupProvider = FutureProvider<DeviceStartupResult>((ref) async {
  // ref.read, not watch: syncOnStartup() reassigns merchantProvider's state,
  // and watching it here would retrigger this provider (and the whole chain).
  // MerchantNotifier.save() invalidates this provider explicitly when the
  // merchant changes.
  final merchant = await ref.read(merchantProvider.future);
  if (merchant == null) return const DeviceStartupResult.tokenUnavailable();
  return ref.read(merchantProvider.notifier).syncOnStartup();
});
```

No new imports are needed — `flutter_riverpod` (for `FutureProvider`) and `device_startup_result.dart` are already imported in this file.

- [ ] **Step 4: Verify analysis is clean**

Run: `dart analyze lib/features/merchant/state/merchant_notifier.dart`
Expected: `No issues found!`

---

## Task 3: Add the bearer header to `MerchantApi.fetchDeviceToken`

**Files:**
- Modify: `lib/features/merchant/data/merchant_api.dart`

- [ ] **Step 1: Add the `token` parameter and `Authorization` header**

Replace the whole `fetchDeviceToken` method:

```dart
  /// `POST /devices/token` — exchanges device credentials for a short-lived
  /// JWT used as the `Authorization: Bearer` header on the WebSocket handshake.
  Future<DeviceTokenDto> fetchDeviceToken({
    required String deviceId,
    required String deviceSecret,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.devicesToken,
      data: {'device_id': deviceId, 'device_secret': deviceSecret},
    );
    _assertSuccess(response, const {200});
    return DeviceTokenDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
```

with:

```dart
  /// `POST /devices/token` — exchanges device credentials for a short-lived
  /// JWT used as the `Authorization: Bearer` header on the WebSocket handshake.
  ///
  /// [token] is the `/auth/token` webhook JWT, sent as the request's bearer.
  Future<DeviceTokenDto> fetchDeviceToken({
    required String deviceId,
    required String deviceSecret,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      ApiEndpoints.devicesToken,
      data: {'device_id': deviceId, 'device_secret': deviceSecret},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    _assertSuccess(response, const {200});
    return DeviceTokenDto.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
```

`Options` is already imported at the top of this file (`import 'package:dio/dio.dart';`).

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/merchant/data/merchant_api.dart`
Expected: one error remains — `The named parameter 'token' is required ... device_token_repository.dart`. That is fixed in Task 4. All other lines: no issues.

---

## Task 4: Replace `DeviceTokenRepository` caching with an unconditional `mint`

**Files:**
- Modify: `lib/features/orders/data/repositories/device_token_repository.dart`

- [ ] **Step 1: Rewrite the file**

Replace the entire file contents with:

```dart
import '../../../../core/storage/merchant_device_storage.dart';
import '../../../merchant/data/merchant_api.dart';

/// Mints the `POST /devices/token` bearer JWT used to authenticate the
/// live-orders WebSocket handshake.
///
/// The token is **not** cached across launches — [mint] is called on every
/// connect attempt (see the launch-auth-chain spec). The minted token is still
/// written to [MerchantDeviceStorage] so [invalidate] can clear it on a
/// handshake rejection and for parity with `mobile/`.
class DeviceTokenRepository {
  const DeviceTokenRepository(this._api, this._storage);

  final MerchantApi _api;
  final MerchantDeviceStorage _storage;

  /// Mints a fresh device token.
  ///
  /// [webhookToken] is the `/auth/token` JWT, sent as the bearer on
  /// `POST /devices/token`. [deviceId] / [deviceSecret] come from the
  /// `/devices/register` response; when [deviceSecret] is null or empty the
  /// stored secret (from a prior `202` enrolment) is used instead. Throws when
  /// no secret is available from either source.
  Future<String> mint({
    required String webhookToken,
    required String deviceId,
    String? deviceSecret,
  }) async {
    final secret = (deviceSecret != null && deviceSecret.isNotEmpty)
        ? deviceSecret
        : await _storage.deviceSecret;

    if (deviceId.isEmpty || secret == null || secret.isEmpty) {
      throw Exception(
        'Device credentials unavailable for POST /devices/token',
      );
    }

    final dto = await _api.fetchDeviceToken(
      deviceId: deviceId,
      deviceSecret: secret,
      token: webhookToken,
    );

    await _storage.writeDeviceWsToken(dto.token, dto.exp, dto.merchantId);
    return dto.token;
  }

  /// Clears the cached WS token. Call on a 401/403 WebSocket handshake
  /// rejection so the next [mint] result fully replaces it.
  Future<void> invalidate() => _storage.clearDeviceWsToken();
}
```

This removes the `_expiryGuard` constant, `ensureToken`, and the old
`refreshToken` — all now dead.

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/orders/data/repositories/device_token_repository.dart`
Expected: `No issues found!`

Run: `dart analyze lib/features/merchant/data/merchant_api.dart`
Expected: `No issues found!` (Task 3's dangling error is now resolved.)

---

## Task 5: Gate the feed on `deviceStartupProvider` and feed creds into `mint`

**Files:**
- Modify: `lib/features/orders/state/orders_feed_notifier.dart`

- [ ] **Step 1: Add the startup-cred fields**

Find the field declaration:

```dart
  DateTime? _connectedAt;
  String? _merchantId;
```

Replace with:

```dart
  DateTime? _connectedAt;
  String? _merchantId;

  /// `device_id` / `device_secret` from this launch's `/devices/register`
  /// response, captured in [build] and passed to [DeviceTokenRepository.mint].
  String? _startupDeviceId;
  String? _startupDeviceSecret;
```

- [ ] **Step 2: Rewrite the `build()` gate**

Replace this block in `build()`:

```dart
    final merchant = await ref.watch(merchantProvider.future);
    if (merchant == null) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    // Only connect when the device is registered (webhook token present) and
    // its enrollment has been approved by the merchant admin.
    final storage = getIt<MerchantDeviceStorage>();
    final webhookToken = await storage.token;
    if (webhookToken == null || webhookToken.isEmpty) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }
    // Block only when we've affirmatively cached a NON-approved status
    // (pending / deactivated). An absent cache means this device enrolled
    // before the status gate existed, or storage was cleared — fail open and
    // let the orders service authorize the handshake, matching `mobile/`.
    // syncOnStartup() refreshes the cache on launch and the follow-up
    // checkConnection() drops the socket if the device turns out non-approved.
    final deviceStatus = await storage.deviceStatus;
    if (deviceStatus != null && deviceStatus != DeviceStatus.approved) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    unawaited(_connect(merchant.merchantId));
    return OrdersFeedState(
      connection: OrdersFeedConnection.connecting,
      merchantId: merchant.merchantId,
    );
```

with:

```dart
    final merchant = await ref.watch(merchantProvider.future);
    if (merchant == null) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }

    // Block until this launch's auth chain (POST /auth/token →
    // POST /devices/register) has resolved. Only an `approved` result carries
    // the device credentials and means step 1 succeeded — anything else keeps
    // the feed disconnected (the dashboard shows the status dialog).
    final startup = await ref.watch(deviceStartupProvider.future);
    if (!startup.isApproved) {
      return const OrdersFeedState(
        connection: OrdersFeedConnection.disconnected,
      );
    }
    _startupDeviceId = startup.deviceId;
    _startupDeviceSecret = startup.deviceSecret;

    unawaited(_connect(merchant.merchantId));
    return OrdersFeedState(
      connection: OrdersFeedConnection.connecting,
      merchantId: merchant.merchantId,
    );
```

- [ ] **Step 3: Mint the device token inside `_connect()`**

In `_connect()`, replace this block:

```dart
      // Same order as `mobile/`'s OrdersFeedNotifier: refresh the `/auth/token`
      // webhook JWT, then mint the `/devices/token` bearer, then handshake.
      await _ensureWebhookToken(merchantId);
      if (generation != _connectGeneration) return;

      final deviceToken = await _deviceTokenRepo.ensureToken(merchantId);
      if (generation != _connectGeneration) return;
```

with:

```dart
      // Same order as `mobile/`'s OrdersFeedNotifier: refresh the `/auth/token`
      // webhook JWT, then mint the `/devices/token` bearer, then handshake.
      await _ensureWebhookToken(merchantId);
      if (generation != _connectGeneration) return;

      final storage = getIt<MerchantDeviceStorage>();
      final webhookToken = await storage.token;
      if (webhookToken == null || webhookToken.isEmpty) {
        throw StateError('no webhook token available for POST /devices/token');
      }
      final deviceToken = await _deviceTokenRepo.mint(
        webhookToken: webhookToken,
        deviceId: _startupDeviceId ?? await storage.deviceId ?? '',
        deviceSecret: _startupDeviceSecret,
      );
      if (generation != _connectGeneration) return;
```

- [ ] **Step 4: Clear the startup creds in `_teardown()`**

Replace:

```dart
  void _teardown() {
    _resetConnection();
    _merchantId = null;
    _recentEventIds.clear();
    _seenEventIds.clear();
    _hasHydrated = false;
    _muteNotificationsUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }
```

with:

```dart
  void _teardown() {
    _resetConnection();
    _merchantId = null;
    _startupDeviceId = null;
    _startupDeviceSecret = null;
    _recentEventIds.clear();
    _seenEventIds.clear();
    _hasHydrated = false;
    _muteNotificationsUntil = DateTime.fromMillisecondsSinceEpoch(0);
  }
```

- [ ] **Step 5: Verify analysis**

Run: `dart analyze lib/features/orders/state/orders_feed_notifier.dart`
Expected: `No issues found!`

Notes for the implementer:
- `deviceStartupProvider` resolves from `merchant_notifier.dart`, already imported here as `import '../../merchant/state/merchant_notifier.dart';`.
- `DeviceStatus` is still referenced in `checkConnection()` — leave that import and that method untouched. `checkConnection()`'s `storage.deviceStatus` gate stays as a defensive drop for a device deactivated server-side mid-session.
- `_deviceTokenRepo` is still constructed with `DeviceTokenRepository(getIt<MerchantApi>(), getIt<MerchantDeviceStorage>())` — unchanged.

---

## Task 6: Switch the dashboard to `deviceStartupProvider`

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Read the provider instead of calling `syncOnStartup()`**

In `_checkMerchant()`, replace:

```dart
    if (merchant != null) {
      final result = await ref.read(merchantProvider.notifier).syncOnStartup();
      if (!mounted) return;
      _handleDeviceStatus(result.status, result.justApproved, result.reviewNote);
      unawaited(
        ref.read(ordersFeedNotifierProvider.notifier).checkConnection(),
      );
      return;
    }
```

with:

```dart
    if (merchant != null) {
      final result = await ref.read(deviceStartupProvider.future);
      if (!mounted) return;
      _handleDeviceStatus(result.status, result.justApproved, result.reviewNote);
      unawaited(
        ref.read(ordersFeedNotifierProvider.notifier).checkConnection(),
      );
      return;
    }
```

`deviceStartupProvider` comes from the already-imported
`import '../../../merchant/state/merchant_notifier.dart';`.

- [ ] **Step 2: Verify analysis**

Run: `dart analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart`
Expected: `No issues found!`

Note: the `merchant == null` branch (fresh registration via `MerchantFormDialog`)
is unchanged. On that first launch, `register()` runs the chain once and then
`OrdersFeedNotifier.build()` re-runs (merchant now non-null) and triggers
`deviceStartupProvider`, which calls `syncDeviceRegistration()` — a second,
idempotent `/devices/register` (`Idempotency-Key: installId`). This is a
one-time redundant call on the enrolment launch only; accepted, not fixed.

---

## Task 7: Full-project verification

**Files:** none (verification only)

- [ ] **Step 1: Analyze the whole package**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 2: Grep for stragglers**

Run: `grep -rn "ensureToken\|\.refreshToken(merchantId)\|_expiryGuard" lib/`
Expected: the only `refreshToken` hits are `MerchantRepository.refreshToken` /
`MerchantRepositoryImpl.refreshToken` / its call sites in `merchant_notifier.dart`
and `orders_feed_notifier.dart`'s `_ensureWebhookToken` (all still valid —
that's the `/auth/token` refresh, a different method). No `ensureToken` or
`_expiryGuard` hits anywhere.

- [ ] **Step 3: Confirm the wiring by reading the call chain**

Open `lib/features/orders/state/orders_feed_notifier.dart` and confirm:
- `build()` awaits `ref.watch(deviceStartupProvider.future)` before any
  `_connect()`.
- `_connect()` reads `storage.token` (the `/auth/token` JWT) and passes it as
  `webhookToken:` to `_deviceTokenRepo.mint(...)`.
- `mint()` result (`deviceToken`) is passed as `bearerToken:` to
  `repository.connect(merchantId, bearerToken: deviceToken)`.

- [ ] **Step 4: Report done**

Summarize the diff to the user. Do **not** commit (CLAUDE.md git rule). Offer to
run the app / commit if the user wants.

---

## Self-Review

**Spec coverage:**
- "every launch: POST /auth/token" → `syncOnStartup()` calls `repo.refreshToken` unconditionally (existing) — Task 2 keeps it; provider ensures it runs once per launch.
- "auth token success → bearer for /devices/register" → existing `_registerAndPersist` behaviour, unchanged.
- "register done → /devices/token with creds from register response, approved only" → Task 1 (fields), Task 2 (populate on approved), Task 5 (`_connect` passes them to `mint`).
- "/devices/token bearer = auth/token response" → Task 3 (`token` param + header), Task 5 (`webhookToken: storage.token`).
- "/devices/token every launch" → Task 4 (no cache-hit early return).
- "/devices/token response → WS bearer" → already wired (`_connect` → `repository.connect(..., bearerToken: deviceToken)`), confirmed in Task 7 Step 3.
- Ordering guarantee → Task 5 Step 2 (`await ref.watch(deviceStartupProvider.future)` before `_connect`).
- Fallback when approved but no `device_secret` → Task 4 `mint()` (`await _storage.deviceSecret`).
- Merchant-change re-run → Task 2 Step 2 (`ref.invalidate(deviceStartupProvider)`).
- Cleanup (dead `ensureToken` / `refreshToken` / `_expiryGuard`) → Task 4, verified Task 7 Step 2.

**Placeholder scan:** none — every code step shows full replacement text.

**Type consistency:** `mint({required String webhookToken, required String deviceId, String? deviceSecret})` defined in Task 4 and called with exactly those names in Task 5 Step 3. `fetchDeviceToken({required deviceId, required deviceSecret, required token})` defined in Task 3, called with those names in Task 4. `deviceStartupProvider` is a `FutureProvider<DeviceStartupResult>` in Task 2, awaited via `.future` in Tasks 5 and 6. `DeviceStartupResult` ctor params (`status`, `justApproved`, `reviewNote`, `deviceId`, `deviceSecret`) match between Task 1 and Task 2 Step 1.
