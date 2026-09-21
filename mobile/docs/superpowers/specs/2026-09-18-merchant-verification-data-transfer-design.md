# Merchant verification → existing-data transfer prompt — design

**Date:** 2026-09-18
**Scope:** `mobile/` only (Flutter merchant POS app)

## Problem

A device can be running with a `store_id` that the backend doesn't recognize
as a verified merchant (`merchantVerificationProvider` returns `false` —
`POST /auth/token` rejects it, or the device has simply never been able to
reach the backend to check). While in that state, local sales/refunds keep
recording normally but can never sync (`TransactionSyncService.syncPending`
requires `ensureToken(storeId)` to succeed first).

When the operator later corrects this — editing Store Information to a
`store_id` that *does* verify — today nothing tells them that the local
history accumulated under the old, unverified id needs to be pushed to the
newly-active merchant. It will eventually sync (unsynced rows are unsynced
regardless of cause), but any rows that happen to already have `synced_at`
set (e.g. a brief earlier window where a different merchant was verified)
would silently never re-send, since `syncPending` only ever looks at
`WHERE synced_at IS NULL`.

This design adds a one-time confirmation prompt at the moment a store ID
change fixes verification, offering to mark all local sales/refunds unsynced
so the next sync run (periodic worker or manual "Sync" button) sends the
complete local history to the now-active, verified merchant.

## Non-goals

- **No immediate/forced sync.** Confirming the prompt only flips
  `synced_at` back to `null` via the existing
  `TransactionSyncService.unsyncAll`. Delivery still goes through the
  existing periodic worker (≤15 min) or a manual sync, unchanged.
- **No per-row merchant tagging.** `sales`/`refunds` have no merchant/store
  column — there is exactly one active `store_id` per device
  (`store_info` is a single row). "Transfer" means "make everything eligible
  to (re-)send under whichever `store_id` is active now", not a per-row
  re-attribution.
- **No changes to `StoreInfoNotifier.save()`, `MerchantDeviceNotifier`, or
  the first-run onboarding gate (`_StoreIdSetupGate`).** The onboarding path
  never has prior local data to offer, so it's excluded rather than
  special-cased.
- **No new dialog widget.** Reuses the existing `showSetupPromptDialog`
  (`lib/widgets/setup_prompt_dialog.dart`), which already supports a
  primary/secondary confirm pattern.
- **No change to what counts as "verified".** Still whatever
  `merchantVerificationProvider` already decides (`POST /auth/token`
  succeeding for the store id).

## Design

### 1. Trigger condition

Computed entirely on the view side, using state already available before
`StoreInfoNotifier.save()` is even called — no notifier changes needed:

```
offer = storeIdChanged && !previouslyVerified && verifiedOnline (after save) && hasExistingData
```

- `storeIdChanged` — `newStoreId.trim() != previousStoreId.trim()`, both
  already in hand in the view (the text controller's current value vs. the
  `initial*` the form/dialog was built with).
- `previouslyVerified` — `ref.read(merchantVerificationProvider).value ?? false`,
  read **before** calling `save()`. Both edit surfaces
  (`_StoreInfoForm` in `store_info_screen.dart`, `StoreDetailsDialog` in
  `store_details_dialog.dart`) already `ref.watch`/build after this provider
  has resolved (it gates the `DeviceRegistrationStatusCard`), so reading
  `.value` here is a cache hit, not a new network call. If it happens to be
  unresolved (`null`), it's treated as `false` — a narrow edge case (first
  paint) that at worst causes one extra offer; not worth extra machinery for.
- `verifiedOnline` — the existing `bool` `save()` already returns, unchanged.
- `hasExistingData` — new `SalesDao.hasAnyTransactions()` check, run only
  after `save()` succeeds (no point querying it if the save failed or
  nothing changed).

### 2. DAO — `lib/core/database/daos/sales_dao.dart`

One new method, next to the other sync-related queries:

```dart
/// True if this device has any local sale or refund at all, regardless of
/// sync state. Used to decide whether a verified store-id change is worth
/// offering to transfer existing history to.
Future<bool> hasAnyTransactions() async {
  final sale = await (select(salesTable)..limit(1)).getSingleOrNull();
  if (sale != null) return true;
  final refund = await (select(refundsTable)..limit(1)).getSingleOrNull();
  return refund != null;
}
```

### 3. Shared view helpers — `lib/features/settings/view/store_info_screen.dart`

Colocated next to the existing `storeSaveErrorMessage`/`generateStoreId`
top-level functions, which `store_details_dialog.dart` already imports via
`show` — same pattern extended, not a new file:

```dart
Future<bool> shouldOfferDataTransfer(
  WidgetRef ref, {
  required String previousStoreId,
  required String newStoreId,
}) async {
  if (previousStoreId.trim() == newStoreId.trim()) return false;
  final previouslyVerified =
      ref.read(merchantVerificationProvider).value ?? false;
  if (previouslyVerified) return false;
  return ref.read(databaseProvider).salesDao.hasAnyTransactions();
}

Future<void> maybeOfferDataTransfer(BuildContext context, WidgetRef ref) {
  return showSetupPromptDialog(
    context,
    type: SetupPromptType.info,
    title: 'Existing Data Found',
    message:
        'This device has local sales data. It will be transferred to the '
        'now-active merchant on the next sync.',
    primaryButtonText: 'Transfer',
    secondaryButtonText: 'Not Now',
    onPrimaryPressed: () async {
      await TransactionSyncService.unsyncAll(ref.read(databaseProvider));
      if (context.mounted) Navigator.of(context).pop();
    },
    onSecondaryPressed: () => Navigator.of(context).pop(),
  );
}
```

### 4. Call sites

Both existing "regular edit" save flows gain the same three lines, wrapped
around the unchanged `save()` call:

**`store_info_screen.dart`, `_StoreInfoForm.onSave`:**
```dart
onSave: (storeId, name, address, taxRate, currency, footer, tin, terminalName) async {
  final offer = await shouldOfferDataTransfer(
    ref,
    previousStoreId: initialStoreId,
    newStoreId: storeId,
  );
  bool verifiedOnline;
  try {
    verifiedOnline = await ref.read(storeInfoProvider.notifier).save(...); // unchanged args
  } catch (error) {
    if (context.mounted) _showStoreSaveError(context, error);
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store info saved')));
  }
  if (verifiedOnline && offer && context.mounted) {
    await maybeOfferDataTransfer(context, ref);
  }
},
```
(`save()`'s call here currently discards its return value — it needs to be
captured into `verifiedOnline` for this check; everything else about the
call is unchanged.)

**`store_details_dialog.dart`, `StoreDetailsDialog.onSave`:**
```dart
Future<void> onSave() async {
  if (!(formKey.currentState?.validate() ?? false)) return;
  isSubmitting.value = true;
  errorMessage.value = null;
  final offer = await shouldOfferDataTransfer(
    ref,
    previousStoreId: info?.storeId ?? '',
    newStoreId: storeIdCtrl.text.trim(),
  );
  try {
    await ref.read(storeInfoProvider.notifier).save(...); // unchanged args
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (offer && context.mounted) await maybeOfferDataTransfer(context, ref);
  } catch (e) {
    errorMessage.value = storeSaveErrorMessage(e);
    isSubmitting.value = false;
  }
}
```
`save()` throwing here already means verification failed, so no extra
`verifiedOnline` check is needed on this path — reaching the offer call at
all implies success.

### 5. Data transfer action

Reuses the existing `TransactionSyncService.unsyncAll(db)`
(`lib/core/services/transaction_sync/transaction_sync_service.dart:48`) —
the same static method the Transactions screen's "Unsync Transactions"
button already calls. No new sync/service code. It sets every row's
`synced_at` back to `null`; delivery happens on the next periodic tick
(`transaction_sync_worker.dart`, every 15 minutes) or a manual sync.

### Edge cases

- **Declining the prompt ("Not Now")** — no state change. The operator can
  still reach the same effect later via the Transactions screen's existing
  manual "Unsync Transactions" button.
- **Save fails (rejected/unreachable store id)** — the offer is never shown;
  `shouldOfferDataTransfer` was already computed, but the call sites only
  invoke `maybeOfferDataTransfer` after a successful save.
- **Fresh device, no local data yet** — `hasAnyTransactions()` returns
  `false`, so the prompt never appears. Covers the onboarding gate
  implicitly (it doesn't call this helper at all, but even if it did, the
  condition would be false).
- **Editing only name/address/etc., not the store id** — `storeIdChanged` is
  false, no prompt, no matter how much local data exists.

## Verification

From `mobile/`:

```bash
dart analyze
```

No new test files (per project convention). Manual check: with a device
whose `store_id` doesn't verify and has at least one recorded sale, edit
Store Information to a `store_id` that does verify → confirm the "Existing
Data Found" dialog appears; tap **Transfer** → confirm the Transactions
screen's rows show as unsynced and the next sync (manual button or a forced
worker tick) pushes them. Repeat and tap **Not Now** → confirm nothing
changes and no crash.

## Files touched

| File | Change |
|---|---|
| `lib/core/database/daos/sales_dao.dart` | new `hasAnyTransactions()` |
| `lib/features/settings/view/store_info_screen.dart` | new `shouldOfferDataTransfer`/`maybeOfferDataTransfer` helpers; `_StoreInfoForm.onSave` updated |
| `lib/features/dashboard/view/store_details_dialog.dart` | `onSave` updated to call the new helpers |
