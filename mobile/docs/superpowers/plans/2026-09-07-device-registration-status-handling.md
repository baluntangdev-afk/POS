# Device Registration Status Handling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parse and persist the `status` + `merchant_name` fields from `POST /devices/register`, apply the merchant name to local store info, and show status-aware messaging (a persistent card + a one-time dialog) on the Store Information screen.

**Architecture:** The register response DTO gains `merchantName`. `MerchantDeviceStorage` persists the last known `status` and `merchant_name` so they survive restarts; `MerchantDeviceNotifier` hydrates them in `build()` and exposes a `refreshStatus()` that idempotently re-calls `/devices/register`. A new `DeviceRegistrationStatusCard` widget renders the current status at the top of the Store Info form, and `handleMerchantDeviceOutcome` switches its dialog copy on the status.

**Tech Stack:** Flutter, Hooks Riverpod (`AsyncNotifier`), `dart_mappable` codegen, `flutter_secure_storage`.

---

## Conventions for this plan

- **Working directory for all commands:** `C:\Users\Jufiel\Documents\POS_ENTERPRISE\POS_KIOSK\mobile` (the `mobile/` package).
- **No new test files.** Per project convention, verification is `dart analyze` (and `dart run build_runner build` after any annotated-class change). Every task ends with an analyze step.
- **No git commits.** Repo rule: never commit unless the user explicitly asks. Each task ends at a verified-clean checkpoint; the user commits when ready.
- **Stay in `mobile/`.** Do not touch `be/`, `kiosk/`, or `mobile_merchant/`.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `lib/data/backend_api/schemas/device_registration_dto.dart` | Register response contract | Modify — add `merchantName` |
| `lib/data/backend_api/schemas/device_registration_dto.mapper.dart` | Generated mapper | Regenerate |
| `lib/data/secure_storage/sources/merchant_device_storage.dart` | Persisted device identifiers | Modify — add status + merchant-name keys |
| `lib/features/live_orders/repositories/merchant_device_repository.dart` | Register call + persistence orchestration | Modify — persist + expose last-known getters |
| `lib/features/live_orders/entities/merchant_device_state.dart` | In-memory device state | Modify — persisted fields + getters |
| `lib/features/live_orders/state/merchant_device_notifier.dart` | Device state lifecycle | Modify — hydrate + `refreshStatus()` |
| `lib/features/settings/state/store_info_notifier.dart` | Store info + provisioning | Modify — apply `registration.merchantName` |
| `lib/features/live_orders/view/device_registration_status_visual.dart` | Status → colour/icon/copy mapping (shared by card + dialog) | Create |
| `lib/features/live_orders/view/device_registration_status_card.dart` | Persistent status card widget | Create |
| `lib/features/live_orders/view/device_registration_prompt.dart` | One-time dialog on status change | Modify |
| `lib/features/settings/view/store_info_screen.dart` | Mounts the card | Modify |

---

## Task 1: Add `merchantName` to `DeviceRegistrationDto`

**Files:**
- Modify: `lib/data/backend_api/schemas/device_registration_dto.dart`
- Regenerate: `lib/data/backend_api/schemas/device_registration_dto.mapper.dart`

- [ ] **Step 1: Add the field**

In `device_registration_dto.dart`, add the constructor parameter (after `this.reviewNote,`):

```dart
    this.reviewNote,
    this.merchantName,
  });
```

And add the field declaration (after the `reviewNote` field):

```dart
  /// Optional note left by the reviewer.
  final String? reviewNote;

  /// Human-readable merchant/store name the backend resolved for this device,
  /// when it sent one. Present on the register success payload alongside
  /// [status].
  final String? merchantName;
```

- [ ] **Step 2: Regenerate the mapper**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: completes with `Succeeded`; `device_registration_dto.mapper.dart` now contains a `_f$merchantName` field keyed `r'merchant_name'` and `merchantName: data.dec(_f$merchantName)` in `_instantiate`.

- [ ] **Step 3: Analyze**

Run: `dart analyze lib/data/backend_api/schemas/device_registration_dto.dart`
Expected: `No issues found!`

- [ ] **Step 4: Checkpoint** — changes staged for user review; do not commit.

---

## Task 2: Persist status + merchant name in `MerchantDeviceStorage`

**Files:**
- Modify: `lib/data/secure_storage/sources/merchant_device_storage.dart`

- [ ] **Step 1: Add the keys**

In the `MerchantDeviceStorage` class, after `_registeredStoreIdKey`:

```dart
  static const _registeredStoreIdKey = 'merchant_registered_store_id';
  static const _lastStatusKey = 'merchant_device_status';
  static const _merchantNameKey = 'merchant_device_merchant_name';
```

- [ ] **Step 2: Add accessors**

After the `writeDeviceSecret` method (before `ensureInstallId`):

```dart
  /// The `status` from the most recent `POST /devices/register` response
  /// (`pending`, `approved`, `deactivated`, ...). Survives restarts so the
  /// Store Info screen can show the last known state.
  Future<String?> get lastStatus => _storage.read(key: _lastStatusKey);

  Future<void> writeLastStatus(String status) =>
      _storage.write(key: _lastStatusKey, value: status);

  /// The `merchant_name` the backend resolved for this device, if any.
  Future<String?> get merchantName => _storage.read(key: _merchantNameKey);

  Future<void> writeMerchantName(String name) =>
      _storage.write(key: _merchantNameKey, value: name);
```

- [ ] **Step 3: Clear them in `clear()`**

```dart
  Future<void> clear() async {
    await _storage.delete(key: _deviceIdKey);
    await _storage.delete(key: _deviceSecretKey);
    await _storage.delete(key: _registeredStoreIdKey);
    await _storage.delete(key: _lastStatusKey);
    await _storage.delete(key: _merchantNameKey);
  }
```

- [ ] **Step 4: Analyze**

Run: `dart analyze lib/data/secure_storage/sources/merchant_device_storage.dart`
Expected: `No issues found!`

- [ ] **Step 5: Checkpoint.**

---

## Task 3: Persist + expose last-known status/name in the repository

**Files:**
- Modify: `lib/features/live_orders/repositories/merchant_device_repository.dart`

- [ ] **Step 1: Extend the abstract interface**

In `abstract class MerchantDeviceRepository`, after `registeredStoreId()`:

```dart
  /// The `store_id` the persisted registration belongs to, if any.
  Future<String?> registeredStoreId();

  /// The `status` from the last register response persisted locally, if any.
  Future<String?> lastKnownStatus();

  /// The `merchant_name` from the last register response persisted locally,
  /// if any.
  Future<String?> lastKnownMerchantName();
```

- [ ] **Step 2: Persist in `registerDevice`**

In `MerchantDeviceRepositoryImpl.registerDevice`, replace the body from
`await _storage.writeRegisteredStoreId(storeId);` through `return registration;`:

```dart
    await _storage.writeRegisteredStoreId(storeId);
    await _storage.writeLastStatus(registration.status);
    final merchantName = registration.merchantName?.trim() ?? '';
    if (merchantName.isNotEmpty) {
      await _storage.writeMerchantName(merchantName);
    }
    return registration;
```

- [ ] **Step 3: Implement the getters**

After the `registeredStoreId` override in `MerchantDeviceRepositoryImpl`:

```dart
  @override
  Future<String?> registeredStoreId() => _storage.registeredStoreId;

  @override
  Future<String?> lastKnownStatus() => _storage.lastStatus;

  @override
  Future<String?> lastKnownMerchantName() => _storage.merchantName;
```

- [ ] **Step 4: Analyze**

Run: `dart analyze lib/features/live_orders/repositories/merchant_device_repository.dart`
Expected: `No issues found!`

- [ ] **Step 5: Checkpoint.**

---

## Task 4: Add persisted fields + getters to `MerchantDeviceState`

**Files:**
- Modify: `lib/features/live_orders/entities/merchant_device_state.dart`

- [ ] **Step 1: Add constructor params + fields**

Replace the constructor and the `registration` field block so the class reads:

```dart
  const MerchantDeviceState({
    this.deviceId,
    this.registeredStoreId,
    this.registration,
    this.persistedStatus,
    this.persistedMerchantName,
    this.isRegistering = false,
    this.error,
    this.errorMessage,
  });

  /// The `device_id` persisted in secure storage, if the device has been
  /// registered before.
  final String? deviceId;

  /// The `store_id` the persisted registration belongs to. Used to decide
  /// whether a store-id change requires re-registration.
  final String? registeredStoreId;

  /// The full record from the most recent registration call this session.
  final DeviceRegistrationDto? registration;

  /// The `status` from the last register response, rehydrated from secure
  /// storage on startup. Used when [registration] is null this session.
  final String? persistedStatus;

  /// The `merchant_name` from the last register response, rehydrated from
  /// secure storage on startup.
  final String? persistedMerchantName;
```

- [ ] **Step 2: Update the `status` getter and add `merchantName`**

Replace the existing `status` getter:

```dart
  bool get isRegistered => deviceId != null;

  /// Review state from the last registration response, falling back to the
  /// value persisted from a previous session.
  String? get status => registration?.status ?? persistedStatus;

  /// Human-readable merchant name from the last registration response,
  /// falling back to the persisted value.
  String? get merchantName =>
      registration?.merchantName ?? persistedMerchantName;
```

- [ ] **Step 3: Update `copyWith`**

Replace the `copyWith` method:

```dart
  MerchantDeviceState copyWith({
    String? deviceId,
    String? registeredStoreId,
    DeviceRegistrationDto? registration,
    String? persistedStatus,
    String? persistedMerchantName,
    bool? isRegistering,
    DeviceRegistrationError? error,
    String? errorMessage,
  }) {
    return MerchantDeviceState(
      deviceId: deviceId ?? this.deviceId,
      registeredStoreId: registeredStoreId ?? this.registeredStoreId,
      registration: registration ?? this.registration,
      persistedStatus: persistedStatus ?? this.persistedStatus,
      persistedMerchantName: persistedMerchantName ?? this.persistedMerchantName,
      isRegistering: isRegistering ?? this.isRegistering,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
```

- [ ] **Step 4: Analyze**

Run: `dart analyze lib/features/live_orders/entities/merchant_device_state.dart`
Expected: `No issues found!` (the notifier will not compile yet — that is Task 5; analyze this file in isolation.)

- [ ] **Step 5: Checkpoint.**

---

## Task 5: Hydrate persisted fields + add `refreshStatus()` to the notifier

**Files:**
- Modify: `lib/features/live_orders/state/merchant_device_notifier.dart`

- [ ] **Step 1: Hydrate in `build()`**

Replace the `build()` method:

```dart
  @override
  Future<MerchantDeviceState> build() async {
    final deviceId = await _repository.currentDeviceId();
    final registeredStoreId = await _repository.registeredStoreId();
    final persistedStatus = await _repository.lastKnownStatus();
    final persistedMerchantName = await _repository.lastKnownMerchantName();
    return MerchantDeviceState(
      deviceId: deviceId,
      registeredStoreId: registeredStoreId,
      persistedStatus: persistedStatus,
      persistedMerchantName: persistedMerchantName,
    );
  }
```

- [ ] **Step 2: Carry persisted fields through every `register(...)` state write**

Replace the whole `register(...)` method with:

```dart
  Future<Result<DeviceRegistrationDto, DeviceRegistrationError>> register(
    RegisterDeviceRequest request, {
    required String storeId,
  }) async {
    final current = state.value ?? const MerchantDeviceState();
    // Guard against a double-submit while a request is already in flight.
    if (current.isRegistering) {
      return const Failure(DeviceRegistrationError.rateLimited);
    }
    state = AsyncData(
      MerchantDeviceState(
        deviceId: current.deviceId,
        registeredStoreId: current.registeredStoreId,
        registration: current.registration,
        persistedStatus: current.persistedStatus,
        persistedMerchantName: current.persistedMerchantName,
        isRegistering: true,
      ),
    );

    try {
      final registration = await _repository.registerDevice(
        request,
        storeId: storeId,
      );
      final merchantName = registration.merchantName?.trim();
      state = AsyncData(
        MerchantDeviceState(
          deviceId: registration.deviceId,
          registeredStoreId: storeId,
          registration: registration,
          persistedStatus: registration.status,
          persistedMerchantName:
              merchantName != null && merchantName.isNotEmpty
                  ? merchantName
                  : current.persistedMerchantName,
        ),
      );
      // The device secret / id are now in secure storage — warm the
      // `/devices/token` cache so the live-orders socket can authenticate
      // without waiting on a first mint. Best-effort: a pending-approval
      // rejection here is normal and the pre-connect step re-mints anyway.
      await _mintDeviceToken(storeId);
      return Success(registration);
    } catch (error, stackTrace) {
      debugPrint('[MerchantDevice] register failed: $error\n$stackTrace');
      final reason = deviceRegistrationErrorFrom(error);
      state = AsyncData(
        MerchantDeviceState(
          deviceId: current.deviceId,
          registeredStoreId: current.registeredStoreId,
          registration: current.registration,
          persistedStatus: current.persistedStatus,
          persistedMerchantName: current.persistedMerchantName,
          error: reason,
          errorMessage: deviceRegistrationMessageFrom(error, reason),
        ),
      );
      return Failure(reason);
    }
  }
```

- [ ] **Step 3: Add `refreshStatus()`**

Insert after the `register(...)` method (before `_mintDeviceToken`):

```dart
  /// Re-runs `POST /devices/register` for the store this device is already
  /// registered against, to pull the current approval [MerchantDeviceState.status].
  /// Idempotent: the Idempotency-Key is the stable install id, so the backend
  /// replays the current record rather than creating a new enrollment. No-op
  /// when the device is not registered yet or has no stored store id.
  Future<void> refreshStatus() async {
    try {
      final loaded = await future;
      if (loaded.isRegistering || !loaded.isRegistered) return;
      final storeId = loaded.registeredStoreId?.trim() ?? '';
      if (storeId.isEmpty) return;

      final name = loaded.merchantName?.trim();
      final request = await ref
          .read(deviceIdentityProvider)
          .describe(name: name == null || name.isEmpty ? 'POS Device' : name);
      await register(request, storeId: storeId);
    } catch (error, stackTrace) {
      debugPrint(
        '[MerchantDevice] refreshStatus skipped: $error\n$stackTrace',
      );
    }
  }
```

- [ ] **Step 4: Regenerate (no annotated changes here, but keep codegen consistent)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded`.

- [ ] **Step 5: Analyze**

Run: `dart analyze lib/features/live_orders`
Expected: `No issues found!`

- [ ] **Step 6: Checkpoint.**

---

## Task 6: Apply `registration.merchantName` in `StoreInfoNotifier`

**Files:**
- Modify: `lib/features/settings/state/store_info_notifier.dart`

- [ ] **Step 1: Apply after registration**

In `_provisionForStore`, replace the `if (storeIdChanged) { ... }` block:

```dart
      if (storeIdChanged) {
        // `/auth/token` runs before `/devices/register` and already resolves
        // the merchant name — mirror it into the local store info and use it
        // as the device name we register with.
        final merchantName = (await _refreshToken(storeId))?.trim() ?? '';
        if (merchantName.isNotEmpty) {
          await applyMerchantName(merchantName);
        }
        await ref
            .read(merchantDeviceNotifierProvider.notifier)
            .registerIfNeeded(
              name: merchantName.isNotEmpty ? merchantName : deviceName,
            );
        // `/devices/register` may resolve its own `merchant_name` — prefer it
        // when present so the form matches what the backend has on file.
        final registeredName = ref
                .read(merchantDeviceNotifierProvider)
                .value
                ?.registration
                ?.merchantName
                ?.trim() ??
            '';
        if (registeredName.isNotEmpty && registeredName != merchantName) {
          await applyMerchantName(registeredName);
        }
      }
```

- [ ] **Step 2: Analyze**

Run: `dart analyze lib/features/settings/state/store_info_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 3: Checkpoint.**

---

## Task 7: Create the status → visual/copy mapping

**Files:**
- Create: `lib/features/live_orders/view/device_registration_status_visual.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/setup_prompt_dialog.dart';

/// Normalised device-registration status buckets. `rejected` collapses into
/// [DeviceRegistrationStatus.deactivated]; anything unrecognised (or null) is
/// [DeviceRegistrationStatus.unknown].
enum DeviceRegistrationStatus { pending, approved, deactivated, unknown }

DeviceRegistrationStatus deviceRegistrationStatusFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pending':
      return DeviceRegistrationStatus.pending;
    case 'approved':
      return DeviceRegistrationStatus.approved;
    case 'deactivated':
    case 'rejected':
      return DeviceRegistrationStatus.deactivated;
    default:
      return DeviceRegistrationStatus.unknown;
  }
}

/// Visual treatment + copy for a device-registration status, shared by the
/// persistent status card and the one-time dialog.
class DeviceRegistrationStatusVisual {
  const DeviceRegistrationStatusVisual({
    required this.color,
    required this.icon,
    required this.headline,
    required this.dialogTitle,
    required this.dialogType,
    required this.primaryButtonText,
    required this.body,
  });

  final Color color;
  final IconData icon;

  /// Short label for the status card.
  final String headline;

  /// Title for the one-time dialog.
  final String dialogTitle;
  final SetupPromptType dialogType;
  final String primaryButtonText;

  /// One-sentence explanation. [merchant] is already interpolated.
  final String body;

  static DeviceRegistrationStatusVisual of(String? rawStatus, String? merchantName) {
    final merchant = (merchantName?.trim().isNotEmpty ?? false)
        ? merchantName!.trim()
        : 'your merchant account';
    final status = deviceRegistrationStatusFrom(rawStatus);
    switch (status) {
      case DeviceRegistrationStatus.pending:
        return DeviceRegistrationStatusVisual(
          color: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
          headline: 'Waiting for approval',
          dialogTitle: 'Device Pending Approval',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body:
              'This device was submitted to $merchant and is waiting for '
              'approval. You can keep using the POS in the meantime — live '
              'orders begin once it is approved.',
        );
      case DeviceRegistrationStatus.approved:
        return DeviceRegistrationStatusVisual(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          headline: 'Device approved',
          dialogTitle: 'Device Approved',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body:
              'This device is approved for $merchant. Live orders are now '
              'enabled.',
        );
      case DeviceRegistrationStatus.deactivated:
        return DeviceRegistrationStatusVisual(
          color: AppColors.error,
          icon: Icons.block_rounded,
          headline: 'Device deactivated',
          dialogTitle: 'Device Deactivated',
          dialogType: SetupPromptType.warning,
          primaryButtonText: 'OK',
          body:
              'This device\'s access to $merchant has been turned off. Live '
              'orders are paused. Contact your merchant administrator to '
              'restore access.',
        );
      case DeviceRegistrationStatus.unknown:
        final raw = rawStatus?.trim() ?? '';
        return DeviceRegistrationStatusVisual(
          color: AppColors.primary,
          icon: Icons.info_rounded,
          headline: raw.isEmpty ? 'Registration status' : 'Status: $raw',
          dialogTitle: 'Device Status',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body: raw.isEmpty
              ? 'This device\'s registration status is not known yet.'
              : 'This device\'s registration status is \'$raw\'.',
        );
    }
  }
}
```

- [ ] **Step 2: Analyze**

Run: `dart analyze lib/features/live_orders/view/device_registration_status_visual.dart`
Expected: `No issues found!`

- [ ] **Step 3: Checkpoint.**

---

## Task 8: Create the `DeviceRegistrationStatusCard` widget

**Files:**
- Create: `lib/features/live_orders/view/device_registration_status_card.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/merchant_device_notifier.dart';
import 'device_registration_status_visual.dart';

/// Always-visible summary of this device's registration status, shown at the
/// top of the Store Information form. Renders nothing until the device has been
/// registered at least once.
class DeviceRegistrationStatusCard extends ConsumerWidget {
  const DeviceRegistrationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(merchantDeviceNotifierProvider).value;
    if (state == null || state.deviceId == null) {
      return const SizedBox.shrink();
    }

    final visual =
        DeviceRegistrationStatusVisual.of(state.status, state.merchantName);
    final busy = state.isRegistering;
    final merchant = state.merchantName?.trim() ?? '';

    // NOTE: a non-uniform `Border` cannot be combined with `borderRadius`
    // (Flutter assertion). Use a uniform status-tinted border instead.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.card,
        border: Border.all(color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visual.icon, color: visual.color, size: 22),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  visual.headline,
                  style: AppTextStyles.headingSm
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          if (merchant.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              merchant,
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
          ],
          const Gap(AppSpacing.sm),
          Text(
            visual.body,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy
                  ? null
                  : () => ref
                      .read(merchantDeviceNotifierProvider.notifier)
                      .refreshStatus(),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(busy ? 'Checking…' : 'Check status'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `dart analyze lib/features/live_orders/view/device_registration_status_card.dart`
Expected: `No issues found!`

- [ ] **Step 3: Checkpoint.**

---

## Task 9: Make the dialog status-aware

**Files:**
- Modify: `lib/features/live_orders/view/device_registration_prompt.dart`

- [ ] **Step 1: Replace the file body**

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/setup_prompt_dialog.dart';
import '../entities/merchant_device_state.dart';
import '../use_cases/device_registration_error.dart';
import 'device_registration_status_visual.dart';

// Module-level guards so that if more than one screen listens at once
// (dashboard setup flow + settings store-info screen), only the first
// reaction wins and dialogs never stack.
String? _shownStatusKey; // '<deviceId>|<status>'
DeviceRegistrationError? _shownError;

void handleMerchantDeviceOutcome(
  BuildContext context,
  MerchantDeviceState? previous,
  MerchantDeviceState? next,
) {
  if (next == null) return;

  final status = next.status?.trim().toLowerCase();
  final deviceId = next.registration?.deviceId ?? next.deviceId;
  if (status != null && status.isNotEmpty && deviceId != null) {
    final key = '$deviceId|$status';
    if (key != _shownStatusKey) {
      _shownStatusKey = key;
      _shownError = null;
      final visual =
          DeviceRegistrationStatusVisual.of(next.status, next.merchantName);
      unawaited(
        showSetupPromptDialog(
          context,
          type: visual.dialogType,
          title: visual.dialogTitle,
          message: visual.body,
          primaryButtonText: visual.primaryButtonText,
        ),
      );
      return;
    }
  }

  final error = next.error;
  if (error != null && error != _shownError && error != previous?.error) {
    _shownError = error;
    unawaited(
      showSetupPromptDialog(
        context,
        type: SetupPromptType.error,
        title: 'Device Registration Failed',
        message:
            '${next.errorMessage ?? error.message}\n\n'
            'It will retry the next time store info is saved.',
        primaryButtonText: 'OK',
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `dart analyze lib/features/live_orders/view/device_registration_prompt.dart`
Expected: `No issues found!`

- [ ] **Step 3: Checkpoint.**

---

## Task 10: Mount the card on the Store Info screen

**Files:**
- Modify: `lib/features/settings/view/store_info_screen.dart`

- [ ] **Step 1: Add the import**

After `import '../../live_orders/view/device_registration_prompt.dart';`:

```dart
import '../../live_orders/view/device_registration_prompt.dart';
import '../../live_orders/view/device_registration_status_card.dart';
```

- [ ] **Step 2: Render it as the first child of the form `ListView`**

In `_StoreInfoForm.build`, the `ListView(...)` `children:` list currently starts
with `SectionCard(title: 'Basic Info', ...)`. Insert before it:

```dart
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const DeviceRegistrationStatusCard(),
          const Gap(AppSpacing.lg),
          SectionCard(
            title: 'Basic Info',
```

- [ ] **Step 3: Analyze the whole package**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 4: Full codegen sanity check**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded`, no changes beyond `device_registration_dto.mapper.dart` from Task 1.

- [ ] **Step 5: Checkpoint.**

---

## Task 11: Manual verification pass

- [ ] **Step 1: Confirm analyze is clean**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 2: Trace the four scenarios against the code (no runtime needed)**

Confirm by reading:
1. **approved response** (the sample payload) → `register()` stores `status: 'approved'` + `merchant_name`; `store_info_notifier` calls `applyMerchantName('Uncle Brew - IT PARK')` so Store Name + Terminal Name update; card shows green "Device approved"; dialog fires once with the approved copy.
2. **pending** → card shows amber "Waiting for approval"; dialog fires with pending copy; `_shownStatusKey` = `<id>|pending`.
3. **deactivated / rejected** → card shows red "Device deactivated"; dialog is `warning` type; socket untouched (no code path changed).
4. **unknown status string** → card shows `Status: <raw>` in primary colour; fallback dialog copy.
5. **App restart, no store-id change** → `build()` hydrates `persistedStatus` / `persistedMerchantName`; card renders from those; "Check status" calls `refreshStatus()` which re-POSTs `/devices/register`.

- [ ] **Step 3: Checkpoint** — feature complete; hand back to user for commit.

---

## Self-Review Notes

- **Spec §1 (DTO merchantName):** Task 1.
- **Spec §2 (storage keys):** Task 2.
- **Spec §3 (repository persist + getters):** Task 3.
- **Spec §4 (state fields/getters):** Task 4.
- **Spec §5 (notifier hydrate + refreshStatus):** Task 5.
- **Spec §6 (apply merchant_name):** Task 6.
- **Spec §7 (status card):** Tasks 7–8, mounted in Task 10.
- **Spec §8 (status-aware dialog):** Task 9 (copy centralised in Task 7's `DeviceRegistrationStatusVisual` so card and dialog cannot drift).
- **Non-goal (socket untouched on deactivated):** verified in Task 11 Step 2.
- **Naming consistency:** `refreshStatus()`, `lastKnownStatus()`, `lastKnownMerchantName()`, `persistedStatus`, `persistedMerchantName`, `DeviceRegistrationStatusVisual.of(rawStatus, merchantName)` used identically across Tasks 3–10.
