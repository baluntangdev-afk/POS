# Cashier Daily Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the Transactions screen's "Cashier Daily Report" button to a new printable receipt-style screen showing the cashier's daily totals and an itemized SALES BY PRODUCT breakdown.

**Architecture:** New backend endpoint `GET /api/v1/reports/cashier-daily-report` (service + mapper + DTO mirroring the existing cashier X-Reading pattern), and a parallel slice in the kiosk's existing `cashier_report` feature module (DTO → entity → repository → notifier → preview screen + ESC/POS print). Shared receipt-preview widgets are extracted from the X-Reading screen so both screens use them.

**Tech Stack:** NestJS + TypeORM (query builder, raw rows), Jest; Flutter + hooks_riverpod, dart_mappable (build_runner), go_router_builder, esc_pos_utils_plus.

**Spec:** `docs/superpowers/specs/2026-07-10-cashier-daily-report-design.md`

> Note: per project CLAUDE.md, no git commits are made by the agent; commit steps are omitted.

---

### Task 1: Backend — DTO + raw-row interfaces

**Files:**
- Create: `be/src/reports/dto/cashier-daily-report-response.dto.ts`
- Modify: `be/src/reports/reports.interface.ts` (append raw-row interfaces)

- [ ] **Step 1:** Create `CashierDailyReportResponseDto` with nested `ProductSalesLineDto { quantity: number; productName: string; amount: number }` and `CashLedgerEntryDto { time: string; reference: string | null; amount: number }`. Top-level fields: `cashierName`, `terminalName`, `businessDate`, `reportGeneratedAt`, `grossSales`, `vatableSales`, `vatAmount`, `vatExemptSales`, `zeroRatedSales`, `netOfTax`, `transactionCount`, `totalQuantity`, `totalCashSales`, `cashSalesCount`, `salesByProduct: ProductSalesLineDto[]`, `cashLedger: CashLedgerEntryDto[]`. All annotated with `@ApiProperty` like `cashier-x-reading-response.dto.ts`.
- [ ] **Step 2:** Append to `reports.interface.ts`:

```ts
/** Raw row for cashier daily report's per-product sales breakdown. */
export interface CashierProductSalesRawRow {
  productName: string;
  quantity?: string | number | null;
  amount?: string | number | null;
}

/** Raw row for cashier daily report's cash totals (sum + count of Cash payments). */
export interface CashierCashSalesRawRow {
  totalCashSales?: string | number | null;
  cashSalesCount?: string | number | null;
}
```

(The daily report's other queries reuse the existing `CashierSalesTotalsRawRow`, `CashierTaxRawRow`, `CashierVatExemptRawRow`, `CashierQuantityRawRow`, and `CashierPaymentLedgerRawRow` shapes.)

### Task 2: Backend — mapper + unit spec (TDD)

**Files:**
- Create: `be/src/reports/mapper/cashier-daily-report.mapper.spec.ts`
- Create: `be/src/reports/mapper/cashier-daily-report.mapper.ts`

- [ ] **Step 1:** Write the failing spec: given raw inputs (user with terminal, sales totals, tax, vatExempt, quantity, product rows, cash totals, cash ledger rows) the mapper produces a DTO where `netOfTax = grossSales - vatAmount`, `zeroRatedSales = 0`, product rows keep SQL (alphabetical) order with numeric quantity/amount, ledger rows map date→ISO string, and every field defaults to 0 / [] when raw rows are undefined/empty.
- [ ] **Step 2:** Run `npx jest --testPathPattern=src/reports/mapper/cashier-daily-report.mapper.spec.ts` — expect FAIL (module not found).
- [ ] **Step 3:** Implement `CashierDailyReportMapper.toDto(raw)` using `toDecimalNumber` (same conventions as `CashierXReadingReportMapper`).
- [ ] **Step 4:** Re-run the spec — expect PASS.

### Task 3: Backend — service, controller route, module registration

**Files:**
- Create: `be/src/reports/services/cashier-daily-report.service.ts`
- Modify: `be/src/reports/reports.controller.ts`, `be/src/reports/reports.module.ts`

- [ ] **Step 1:** `CashierDailyReportService extends BaseReportService<User, CashierDailyReportResponseDto>`; constructor injects `SalesOrder`, `SalesOrderItem`, `Payment`, `User` repositories. `getReport(causer)` runs in parallel: currentUser (with `posTerminal`), salesTotals (reuse X-Reading query), tax, vatExempt, quantity, plus:

```ts
private getSalesByProduct(userId: number): Promise<CashierProductSalesRawRow[]> {
  return this.salesOrderItemRepository
    .createQueryBuilder('soi')
    .innerJoin('soi.salesOrder', 'so')
    .select('soi.description', 'productName')
    .addSelect('SUM(soi.qty)', 'quantity')
    .addSelect('SUM(soi.item_total_amount)', 'amount')
    .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
    .andWhere('so.created_by = :userId', { userId })
    .andWhere('so.so_date::date = CURRENT_DATE')
    .groupBy('soi.description')
    .orderBy('LOWER(soi.description)', 'ASC')
    .getRawMany<CashierProductSalesRawRow>();
}

private getCashSales(userId: number): Promise<CashierCashSalesRawRow | undefined> {
  return this.paymentRepository
    .createQueryBuilder('p')
    .innerJoin('p.salesOrder', 'so')
    .select('SUM(p.amount_paid)', 'totalCashSales')
    .addSelect('COUNT(p.id)', 'cashSalesCount')
    .where('so.status IN (:...statusFilter)', { statusFilter: STATUS_FILTER })
    .andWhere('so.created_by = :userId', { userId })
    .andWhere('so.so_date::date = CURRENT_DATE')
    .andWhere('p.payment_method = :cash', { cash: PaymentMethod.CASH })
    .getRawOne<CashierCashSalesRawRow>();
}

private getCashLedgerEntries(userId: number): Promise<CashierPaymentLedgerRawRow[]> {
  // same as X-Reading's getPaymentLedgerEntries but filtered to Cash
}
```

- [ ] **Step 2:** Controller: `@Get('cashier-daily-report')` returning the DTO, `@CurrentUser() causer`. Module: add service to `providers`.
- [ ] **Step 3:** `npm run build` in `be/` — expect success. (Full lint is skipped deliberately: `npm run lint` autofixes repo-wide.)

### Task 4: Kiosk — DTO schema, entity, mappers, API, repository

**Files:**
- Create: `kiosk/lib/data/backend_api/schemas/cashier_daily_report_dto.dart`
- Create: `kiosk/lib/features/cashier_report/entities/cashier_daily_report.dart`
- Create: `kiosk/lib/features/cashier_report/mappers/cashier_daily_report_mappers.dart`
- Modify: `kiosk/lib/data/backend_api/sources/reports_api.dart` (add `getCashierDailyReport()` hitting `/api/v1/reports/cashier-daily-report`)
- Modify: `kiosk/lib/features/cashier_report/repositories/cashier_report_repository.dart` (add `getDailyReport()` to interface + impl)
- Test: `kiosk/test/features/cashier_report/mappers/cashier_daily_report_mappers_test.dart`

- [ ] **Step 1:** DTO (`@MappableClass`, `part '….mapper.dart'`): `CashierDailyReportDto` mirroring the backend DTO exactly (`reportGeneratedAt`/`time` as `String`), with nested `ProductSalesLineDto` and `CashLedgerEntryDto`.
- [ ] **Step 2:** Entity `CashierDailyReport` (same fields, `DateTime` for timestamps) + extension mappers DTO→entity.
- [ ] **Step 3:** Run `fvm dart run build_runner build --delete-conflicting-outputs` — generates the two `.mapper.dart` files.
- [ ] **Step 4:** Write + run the mapper test (`fvm flutter test test/features/cashier_report/`) — expect PASS.

### Task 5: Kiosk — notifier + test (TDD)

**Files:**
- Create: `kiosk/lib/features/cashier_report/state/cashier_daily_report_notifier.dart`
- Test: `kiosk/test/features/cashier_report/state/cashier_daily_report_notifier_test.dart`

- [ ] **Step 1:** Write failing test mirroring `cashier_x_reading_notifier_test.dart` (load success exposes data; repository error surfaces `AsyncError`).
- [ ] **Step 2:** Implement `CashierDailyReportNotifier` exactly like `CashierXReadingNotifier` (static `printAction` mutation, `load()`, `print()` guarded to Windows, using `encodeEscPosCashierDailyReportProvider`).
- [ ] **Step 3:** `fvm flutter test test/features/cashier_report/` — expect PASS.

### Task 6: Kiosk — ESC/POS encoder

**Files:**
- Create: `kiosk/lib/features/cashier_report/use_cases/encode_esc_pos_cashier_daily_report.dart`

- [ ] **Step 1:** `EncodeEscPosCashierDailyReport.call({report, terminal})` — same logo/header/Isolate structure as `encode_esc_pos_cashier_report.dart`, then: title `CASHIER REPORT`; terminal/date/cashier rows; `Gross Sales`; `Summary:` block (Vatable Sales, VAT Amount, VAT Exempt Sales, Zero Rated Sales); `Others:` block (Net of Tax, No. Transactions, Total Quantity); `Total Cash Sales` + `No. Cash Sales`; `SALES BY PRODUCT` with `QTY x PRODUCT / AMOUNT` header and one row per line (`qty` width 1, name width 7, amount width 4, right-aligned); dashed divider; bold `TOTAL`; `CASH LEDGER` section with per-payment rows (`hh:mm a  CASH#ref`) and bold `***** TOTAL CASH`.

### Task 7: Kiosk — shared preview widgets + daily report screen

**Files:**
- Create: `kiosk/lib/features/cashier_report/view/report_preview_widgets.dart`
- Modify: `kiosk/lib/features/cashier_report/view/cashier_report_preview_screen.dart` (consume shared widgets; no visual change)
- Create: `kiosk/lib/features/cashier_report/view/cashier_daily_report_screen.dart`

- [ ] **Step 1:** Extract `_StoreHeader`, `_Section`, `_KeyValueRow`, `_AmountRow`, `_CountRow`, `_Divider`, `_ErrorView` from the X-Reading preview into public `ReportStoreHeader`, `ReportSection`, `ReportKeyValueRow`, `ReportAmountRow`, `ReportCountRow`, `ReportDashedDivider`, `ReportErrorView`; refactor the X-Reading screen to use them.
- [ ] **Step 2:** Build `CashierDailyReportScreen` — same scaffold/loading/error/receipt-card pattern as the X-Reading preview, sections per the spec layout, `Print Cashier Report` button running `CashierDailyReportNotifier.printAction`.

### Task 8: Kiosk — route + button wiring + codegen + analyze

**Files:**
- Create: `kiosk/lib/navigation/cashier_daily_report_route.dart` (`/cashier-daily-report`, part of router)
- Modify: `kiosk/lib/navigation/router.dart` (import screen, add `part` directive)
- Modify: `kiosk/lib/features/sales/view/transactions_screen.dart` (`_CashierDailyReportButton` → ConsumerWidget: load notifier, spinner while loading, push `CashierDailyReportRoute`)

- [ ] **Step 1:** Add route file + `part` entry, wire the button like `_CashierReportButton`.
- [ ] **Step 2:** `fvm dart run build_runner build --delete-conflicting-outputs` (regenerates `router.g.dart`).
- [ ] **Step 3:** `fvm dart analyze` — expect no new issues; `fvm flutter test test/features/cashier_report/` — expect PASS.

### Task 9: Verification

- [ ] Backend: `npm run build` passes; new mapper spec passes.
- [ ] Kiosk: `fvm dart analyze` clean for touched files; cashier_report tests pass.
- [ ] Manual: run backend + kiosk, open Transactions → Cashier Daily Report → verify totals against the transactions list for today.
