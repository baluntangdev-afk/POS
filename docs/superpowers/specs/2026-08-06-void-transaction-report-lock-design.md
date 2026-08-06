# Lock void transaction once a cashier's closed reports cover it

**Date:** 2026-08-06
**Status:** Approved

## Problem

`receipt_screen.dart` shows a "Void Transaction" button gated only by `!receipt.isVoided`
(`lib/features/ordering/view/receipt_screen.dart:153-168`). There is no check against the
cashier's reporting history, so a cashier can void a sale after it has already been counted in
a closed X-Reading, Daily Report ("Cashier Report"), or Z-Reading — creating a mismatch between
a report that was already generated/printed and the underlying sales data.

(Note: `transactions_screen.dart` also builds an `onVoid` callback per row, but it is never wired
to any tap target in `_TransactionTile.build()` — it's dead code today and out of scope for this
change. `receipt_screen.dart` is the only screen with a working void action.)

## Scope

- Disable the "Void Transaction" button on `receipt_screen.dart` once the sale's cashier has
  closed an X-Reading, Daily Report, or Z-Reading whose period covers that sale.
- Applies per the transaction's owning cashier, not the viewer — an admin/supervisor browsing
  another cashier's already-reported transaction sees the same lock, since the report has
  already reconciled against it.
- Out of scope: wiring up the dead `onVoid` callback in `transactions_screen.dart` (no button
  exists there today; not adding one). Refund flow is unaffected — only void.

## Design

### Lock rule

A sale is void-locked when `sale.createdAt` is **before** the latest of:

- that cashier's last closed X-Reading `periodEnd`
- that cashier's last closed Daily Report `periodEnd`
- the store's last closed Z-Reading `periodEnd` (store-wide — closing a Z-Reading can lock any
  cashier's earlier, still-unvoided sales)

This mirrors the existing period-boundary pattern each report already uses to compute its own
next `periodStart` (`getXReadingPeriodStart`, `getDailyReportPeriodStart`,
`getZReadingPeriodStart` in `lib/core/database/daos/cashier_accounting_dao.dart`).

### `CashierAccountingDao.getVoidLockCutoff`

New method alongside the existing `getXReadingPeriodStart` / `getDailyReportPeriodStart` /
`getZReadingPeriodStart`:

```dart
Future<DateTime> getVoidLockCutoff(int cashierId) async {
  final results = await Future.wait([
    getXReadingPeriodStart(cashierId),
    getDailyReportPeriodStart(cashierId),
    getZReadingPeriodStart(),
  ]);
  return results.reduce((a, b) => a.isAfter(b) ? a : b);
}
```

### `Receipt` entity

`lib/features/ordering/entities/receipt.dart` gains two fields, populated from data the DAO
already has at construction time:

```dart
final int cashierId;
final bool voidLocked;
```

`voidLocked` is computed once, in the DAO, not re-derived in the UI layer — the UI only reads it.

### `SalesDao.getReceiptById`

`lib/core/database/daos/sales_dao.dart:221-...` already reads `sale.cashierId` off the joined
row. After building `sale`, call
`cashierAccountingDao.getVoidLockCutoff(sale.cashierId)` and pass
`voidLocked: !sale.isVoided && sale.createdAt.isBefore(cutoff)` into the `Receipt(...)`
constructor (guarding on `!sale.isVoided` avoids a pointless cutoff query mattering for the
already-voided case, though the button is hidden by `isVoided` regardless).

### `receipt_screen.dart`

The existing button block:

```dart
if (!receipt.isVoided) ...[
  OutlinedButton.icon(onPressed: () => _voidReceipt(context, ref), ... 'Void Transaction' ...),
]
```

becomes:

```dart
if (!receipt.isVoided && !receipt.voidLocked) ...[
  OutlinedButton.icon(onPressed: () => _voidReceipt(context, ref), ... 'Void Transaction' ...),
] else if (receipt.voidLocked) ...[
  const Gap(AppSpacing.md),
  Text(
    'This transaction can no longer be voided — it is already included in a '
    'closed X-Reading, Daily Report, or Z-Reading.',
    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
  ),
]
```

`_voidReceipt` itself is not changed — the button simply won't be present when locked, so the
method can't be reached from the UI.

## Edge cases

- **Sale made after the cashier's last closed report:** `createdAt` is after every relevant
  `periodEnd`, so `getVoidLockCutoff` returns an earlier timestamp than the sale — not locked.
  Voidable as today.
- **No reports closed yet:** all three period-start queries fall back to the Unix epoch
  (`_epoch` in `CashierAccountingDao`), so the cutoff is far in the past — nothing is locked.
- **Z-Reading closed by a different cashier/supervisor:** still locks this cashier's earlier
  sales, since `getZReadingPeriodStart()` is store-wide by design (matches how Z-Reading period
  math already works for report generation).
- **Already-voided sale:** button is hidden by the existing `!receipt.isVoided` check regardless
  of lock state — no behavior change for already-voided transactions.

## Testing

- Unit test `CashierAccountingDao.getVoidLockCutoff`: returns the latest of the three period-ends;
  returns epoch when none exist; correctly isolates X-Reading/Daily Report per cashier while
  treating Z-Reading as shared across cashiers.
- Unit/widget test on `receipt_screen.dart`: button hidden and explanatory text shown when
  `receipt.voidLocked` is true; button shown when both `isVoided` and `voidLocked` are false;
  neither shown when `isVoided` is true.
- Manual: close an X-Reading for a cashier, confirm a sale from before that close can no longer
  be voided from its receipt screen, while a new sale made after the close still can.
