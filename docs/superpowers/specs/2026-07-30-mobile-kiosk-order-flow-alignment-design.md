# Mobile ↔ Kiosk Order Flow Alignment — Design

Date: 2026-07-30

## Context

Kiosk (`kiosk/lib/features/sales/`) and mobile (`mobile/lib/features/ordering/` +
`mobile/lib/features/transactions/`) implement "create a new order" independently and have
diverged significantly:

- Kiosk is backend-driven: draft `Sale` → `POST /sales-orders` → `PATCH .../confirm` →
  server-assigned `soNumber` → `Receipt` built from API responses → ESC/POS print via Windows
  spooler.
- Mobile is fully offline: `CartState`/`CartItem` → one-shot local Drift insert
  (`OrderingNotifier.confirmSale`) → raw autoincrement `id` shown as the "order number" →
  in-memory `SaleReceiptData` → manual Bluetooth thermal print.

Mobile also has an existing but simpler refund flow (`refund_screen.dart`,
`refund_auth_dialog.dart`, `SalesDao.recordRefund`/`getRefundableItems`) that lacks a refund
reason field, a refund method selector, and a formatted refund number — all present in kiosk's
refund flow (`process_refund.dart`, `refund_notifier.dart`, `refund_repository.dart`).

Goal: restructure mobile's order/receipt/void/refund code to mirror kiosk's entity/repository/
use-case/state architecture and behavior as closely as possible, while keeping mobile **fully
offline** (backed by the local Drift DB, not the backend). Backend sync is explicitly out of
scope and will be a separate future project — this design reserves the seams for it but does not
implement it.

## Non-goals

- Backend sync / reconciling a local-only `soNumber` or `refundNumber` with a future
  server-assigned one.
- Any change to kiosk code. Kiosk is the reference; only mobile changes.
- Changing mobile's printing transport (stays Bluetooth ESC/POS via `print_bluetooth_thermal`) —
  this is a legitimate platform difference (Windows spooler vs. Bluetooth thermal on
  Android/tablet hardware), not a flow misalignment.

## Architecture

New layering under `mobile/lib/features/ordering/`, mirroring
`kiosk/lib/features/sales/`:

```
mobile/lib/features/ordering/
  entities/
    sale.dart          # id (int, local), type, items, createdAt, payment, soNumber
    line_item.dart       # replaces CartItem; product/variant/quantity/discount/modifiers
    receipt.dart        # id, store, cashier, docNumber, docDate, type, payment, items,
                         # refunds, refundedAmount, isVoided, voidReason, voidedAt
                         # + kiosk's getters: grossAmount/vatAmount/discountAmount/totalAmount/
                         #   netTotalAmount/hasRefunds/isFullyRefunded/refundedQuantities/
                         #   mainItemsWithAddOns
    receipt_item.dart   # id, sequence, description, quantity, unitPrice, grossAmount,
                         # discountCode/Rate/Amount, vatExclusiveAmount, vatAmount, totalAmount,
                         # isMain, discountBeneficiary{IdNumber,Name}
    refund.dart          # id, docNumber, docDate, receiptId, reason, payment, items
    refund_item.dart     # id, receiptItemId, sequence, description, quantity, refundAmount, isMain
  repositories/
    sale_repository.dart      # abstract + Impl(SalesDao)
    receipt_repository.dart   # abstract + Impl(SalesDao)
    refund_repository.dart    # abstract + Impl(SalesDao)
  use_cases/
    finalize_sale.dart   # sale_repository.save() then receipt_repository.save(draftReceipt)
    void_sale.dart        # SalesDao.voidSale(saleId) + reason
    process_refund.dart   # builds Refund/RefundItem from Receipt + selections, calls
                           # refund_repository.save()
  state/
    ordering_notifier.dart  # cart mutation + confirmSale() -> FinalizeSale
    receipt_notifier.dart    # loads Receipt by id; print(); void_(reason)
  view/
    ordering_screen.dart, payment_screen.dart, receipt_screen.dart (updated)

mobile/lib/features/transactions/
  state/
    refund_notifier.dart   # AsyncNotifier<RefundData>: receipt + form(selectedQuantities,
                            # reason, refundMethod) — mirrors kiosk's RefundNotifier
  view/
    refund_screen.dart (rewritten)  # adds reason field + refund method selector
    refund_auth_dialog.dart (kept, matches kiosk's SupervisorAuthorizationDialog pattern)
    transaction_detail_screen.dart (updated to show refund history via new Receipt getters)
```

`CartState` and `SaleReceiptData` are retired; `Sale`/`Receipt`/`ReceiptItem`/`LineItem` replace
them so mobile and kiosk share vocabulary.

## Order numbering

`SaleRepository.save()` generates a formatted local sequence — `SO-000123` — from the sale row's
autoincrement `id`, stored in a new `so_number` column on `SalesTable`. `id` stays the internal
int PK; `soNumber` is the display/receipt string, exactly mirroring kiosk's separation of `Sale.id`
(UUID) from `Sale.soNumber`. Keeping them distinct now means a future backend-sync pass can
overwrite `soNumber` with a server-assigned value without touching anything else.

Refunds get the same treatment: `RefundRepository.save()` generates `RF-000045` from the refund
row's autoincrement id into a new `refund_number` column on `RefundsTable`.

## Two-phase confirm flow

`OrderingNotifier.confirmSale()` calls `FinalizeSale(sale)`:

1. `SaleRepository.save(sale)` — inserts `SalesTable` (status `pending`) + `SaleItemsTable` +
   `SaleItemModifiersTable` + `PaymentsTable` rows, assigns `soNumber`.
2. `ReceiptRepository.save(draftReceipt)` — flips sale status to `completed`, builds the full
   `Receipt` from the persisted rows.

Both phases hit the same local DB (in one Drift transaction), but the seam mirrors kiosk's
create-then-confirm split so a future backend-sync implementation can swap step 2 for a real API
call with minimal disruption.

## Auto-print

`ReceiptScreen` accepts an `autoPrint` flag on navigation (mirroring kiosk's
`ReceiptRoute(id, autoPrint: true)`) and calls `ReceiptNotifier.print()` on load via the existing
`PrintService`. The manual "Print Receipt" button remains for reprints.

## Void

`ReceiptScreen` gains a void action, calling `ReceiptNotifier.void_(reason)` → `VoidSale` use case
→ `SalesDao.voidSale()` (DAO method already exists, currently unwired to any UI). Voiding requires
supervisor authorization via the same dialog pattern as refunds. After voiding, the receipt view
shows an `isVoided`/`voidReason` banner, matching kiosk.

## Refund flow

- `RefundScreen` gains a reason text field and a refund-method selector (Cash Refund / Card
  Refund / E-wallet Refund), matching kiosk's `RefundForm`.
- Selection/quantity/reason/method state moves from `_RefundScreenState`'s local `setState` into
  `RefundNotifier extends AsyncNotifier<RefundData>`, matching kiosk's `RefundNotifier` shape
  (`toggleItemSelection`, `changeQuantity`, `changeReason`, `changeRefundMethod`,
  `confirmRefund`).
- `ProcessRefund.call({receipt, selectedQuantities, reason, refundMethod})` builds `RefundItem`s
  from the `Receipt`'s `ReceiptItem`s (not straight from DAO rows as today), computes refund
  amounts, and calls `RefundRepository.save()`.
- `Receipt` exposes `refunds`, `refundedAmount`, `refundedQuantities`, `isFullyRefunded`,
  `netTotalAmount`, `mainItemsWithAddOns` (ported from kiosk's `Receipt`) so both
  `ReceiptScreen` and `transaction_detail_screen.dart` can render refund history the same way
  kiosk's `_ReceiptPreview` does, instead of only exposing a flat refundable-items list.

## Migrations required (Drift)

- `SalesTable`: add `so_number TEXT`.
- `RefundsTable`: add `refund_number TEXT`, `method TEXT`.

Both are additive columns; existing rows get generated numbers backfilled on migration (e.g.
`SO-` + zero-padded `id`) so historical transactions display consistently.

## Out of scope (explicitly deferred)

- Backend sync / reconciliation of local `soNumber`/`refundNumber` with a future server-assigned
  one.
- Any change to kiosk code.
- Changing mobile's Bluetooth printing transport.
