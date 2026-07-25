# Phase 5 — POS Terminal / Franchisee Setup Implementation Plan

> **For agentic workers:** Execute task-by-task inline in the current session (per user preference this session — no subagent dispatch). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let mobile capture the legal/compliance identity of the store (TIN, legal name, payment method accounts) that kiosk's PosTerminal/FranchiseeInfo registration captures, and print it on receipts — mobile currently has no TIN field, no payment-methods list, and receipts print with no store identity header at all (confirmed: `PrintService.printReceipt` prints "RECEIPT" / sale # / cashier / date with no store name, address, or TIN anywhere).

**Architecture:** Mobile has no backend, so there's no server-side "terminal registration" to port — this is purely a local settings extension. Add a `tin` column to the existing `store_info` table (schema v2→v3 migration) and a new `payment_methods` table (one-to-many: a store can accept cash, GCash, bank transfer, etc., each with an optional account name/number — mirrors kiosk's `PosTerminalDto.paymentMethods` list shape). Extend `StoreInfoDao`/`StoreInfoScreen` with the TIN field and a payment-methods management list (mirrors Phase 3's `_ManageCategoriesSheet` bottom-sheet CRUD pattern). Print the store's legal name/address/TIN as a receipt header in `PrintService.printReceipt`.

**Tech Stack:** Flutter, Riverpod, Drift (schema migration v2→v3).

---

## Design Decisions

1. **No separate "PosTerminal" vs "FranchiseeInfo" split.** Kiosk has two overlapping concepts (a backend-registered `PosTerminal` with legalName/address/TIN/payment-methods, and a locally-cached `FranchiseeInfo` with legalName/TIN/address/logo) because it's a networked multi-terminal system reconciling server state with a local cache. Mobile is a single local device with one `store_info` row already serving this role — extending it is simpler and avoids a redundant second "identity" concept with no server to reconcile against.
2. **Payment methods as a new table, not JSON on `store_info`.** Unlike Phase 2's write-once "closed snapshot" JSON columns, this is a live-editable list (add/remove/edit anytime) — a proper table with real rows is the right fit, not a serialized blob.

---

## Task 1: Schema — `tin` column + `payment_methods` table (schema v2 → v3)

**Files:**
- Modify: `mobile/lib/core/database/tables/store_info_table.dart` (add `tin` column)
- Create: `mobile/lib/core/database/tables/payment_methods_table.dart`
- Modify: `mobile/lib/core/database/app_database.dart` (register table, bump schemaVersion to 3, extend `onUpgrade`)
- Modify: `mobile/lib/core/database/daos/store_info_dao.dart` (payment-methods CRUD)
- Test: `mobile/test/core/database/daos/store_info_dao_test.dart`

`PaymentMethodsTable`: `id` (autoincrement), `label` (text, e.g. "GCash", "Bank Transfer"), `accountName` (text, nullable), `accountNumber` (text, nullable), `sortOrder` (int, default 0).

- [ ] Write failing tests: schema version is 3, `tin` column round-trips on `store_info`, `insertPaymentMethod`/`getAllPaymentMethods`/`updatePaymentMethod`/`deletePaymentMethod` work against a real in-memory DB.
- [ ] Confirm fail, implement, regenerate Drift codegen, confirm pass.

---

## Task 2: Store Info screen — TIN field + payment methods management

**Files:**
- Modify: `mobile/lib/features/settings/state/store_info_notifier.dart` (add `tin` to save/load)
- Modify: `mobile/lib/features/settings/view/store_info_screen.dart` (add TIN field + "Payment Methods" section with add/edit/delete, mirroring `catalog_screen.dart`'s `_ManageCategoriesSheet` list-with-inline-actions pattern)
- Create: `mobile/lib/features/settings/view/payment_method_form_dialog.dart`
- Test: extend `mobile/test/features/settings/state/store_info_notifier_test.dart` if one exists, else create one covering `tin` persistence.

---

## Task 3: Receipt header shows store identity

**Files:**
- Modify: `mobile/lib/core/services/print_service.dart` (`printReceipt` gains store name/address/TIN header)
- Modify: `mobile/lib/features/ordering/view/receipt_screen.dart` (pass store info through to `printReceipt` — currently calls it with zero args, silently using hardcoded defaults; needs to fetch `store_info` and pass `currency`/`storeFooter`, plus the new store-identity fields)

## Task 4: Manual verification

- [ ] Run full test suite, confirm no regressions.
- [ ] Manually: set TIN + add 2 payment methods in Settings → Store Info, complete a sale, print/preview receipt, confirm store name/address/TIN appear at the top and currency/footer reflect the saved store info (not hardcoded defaults).
