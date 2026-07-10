# Cashier Report (X Reading)

**Date:** 2026-07-09
**Branch:** feature/create-product
**Status:** Approved (design) — pending implementation plan

---

## Problem

Cashiers have no way to see a snapshot of their own current shift's sales while the shift is still open. The only existing reporting surface (`kiosk/lib/features/reports/`) is a manager-facing analytics dashboard scoped by arbitrary date ranges, not a per-cashier, per-terminal, "right now" operational report. There is also no `Suspended`/`shift` concept, and printing anywhere in the kiosk always goes straight to the printer with no preview step.

This spec defines an **X Reading**: a read-only snapshot of "my transactions today, on this terminal," viewable before printing, that never resets counters, closes a shift, or mutates any transaction/inventory/accounting data.

---

## Scope Adjustments From the Original Ask

The original feature request assumed shift-tracking and categorization infrastructure that doesn't exist in this codebase. Rather than build that infrastructure now, this spec scopes the report to what the data model actually supports. These are deliberate, discussed decisions — not gaps to silently patch:

| Original ask | Reality in this codebase | Decision |
|---|---|---|
| Shift number, shift open/close | No `shift`/`cashier_session` entity anywhere. `User.lastLogin` exists but doesn't bound "shift" reliably across re-logins. | "Shift" = `createdBy = current user AND soDate = today's business date AND terminal = current user's assigned terminal`. No new schema. |
| Opening Float / Expected Cash / Cash Difference | No opening float is ever recorded anywhere. | Dropped. Drawer section becomes a single **Cash Collected** line (sum of `Cash` payments), not a full drawer reconciliation. |
| Employee ID | No such field on `User`. | Dropped from Cashier Information. |
| Senior / PWD / Employee / Promo discount categories | Discounts are free-form named rows (currently only "Senior Citizen / PWD" and "KAPENA" exist; no category enum). | Discount Summary groups dynamically by `discounts.name`, whatever rows exist. |
| Bank Transfer / Gift Certificate payment lines | `PaymentMethod` enum is `Cash \| Credit Card \| GCash \| Other`, with a free-text `paymentMethodName` label used only for `Other`. | Sales Summary shows `Cash` / `Credit Card` / `GCash` as fixed lines, then one sub-group per distinct `paymentMethodName` under "Other" (so Bank Transfer/Gift Certificate show up correctly *if* a cashier already logs them that way). |
| VAT Sales / VAT Exempt / VAT Amount / Non-VAT Sales (4 lines) | The system only distinguishes VAT-applicable vs. VAT-exempt (exempt = Senior/PWD discount applied, forces `taxRate = 0` — see `sales-order-calculation.service.ts:113-117`). There's no independent "non-VAT item" concept. | 3 lines: VAT Sales, VAT Amount, VAT-Exempt Sales. No separate "Non-VAT Sales" (would duplicate VAT-Exempt). |
| Completed / Voided / Refunded / Cancelled / Suspended (5 statuses) | Voiding an order **sets** `status = Cancelled` (`void-sales-order.service.ts:66-69`) — "Cancelled" and "Voided" are the same state, not two. There's no `Suspended` concept in this POS. | 3 lines + total: Completed, Voided, Refunded (refund is orthogonal — a `Completed` order can also carry a refund). |
| Report date/cashier picker | N/A (new feature) | Locked to "today + the logged-in cashier + their terminal." No params on the endpoint. Re-opening the report always shows current data — never stale, never requires date entry. |

---

## Backend (`be/`)

### New endpoint

`GET /api/v1/reports/cashier-x-reading` — no query params. Resolves `@CurrentUser()`, scopes every query to that user's orders where `so.so_date::date = CURRENT_DATE`. Terminal name comes from `currentUser.posTerminal` (existing relation, `be/src/users/entities/user.entity.ts:115-117`), not from the sales orders.

Added to the existing `ReportsModule`/`ReportsController` (`be/src/reports/`) — this is a read-only aggregation report exactly like the 8 report types already there, so it reuses `STATUS_FILTER`, the mapper pattern, and `BaseReportService`. No new module.

### New files

- `be/src/reports/services/cashier-x-reading-report.service.ts` — extends `BaseReportService<void, CashierXReadingResponseDto>`. Runs parallel `QueryBuilder` aggregations (`Promise.all`), same style as `TotalReportService`:
  - **Sales by payment method**: adapt `PaymentSalesReportService`'s exact query (`payment-sales-report.service.ts:32-46`) — `COALESCE(p.payment_method_name, p.payment_method::text)` grouping, refund-subtracted `SUM`, `STATUS_FILTER`, minus the date-range params (hardcoded to `CURRENT_DATE` + current user).
  - **Discounts**: same grouping trick against `so_discounts` joined to `discounts`, `GROUP BY discounts.name`.
  - **Transaction counts**: `COUNT` grouped by whether `status = Cancelled` (voided), whether a `Refund` row exists (`EXISTS (SELECT 1 FROM refunds WHERE original_sales_order_id = so.id)`), and completed (`status = Completed AND status != Cancelled`).
  - **Tax**: `SUM(soi.vat_exclusive_amount)` / `SUM(soi.vat_amount)` for non-exempt orders, `SUM(so.final_total_amount)` for exempt orders (reuse `isVatExempt` logic — exempt means the "Senior Citizen / PWD" discount is applied; this can be expressed as an `EXISTS` subquery against `so_discounts`/`discounts.name`).
  - **Other stats**: `AVG`/`MAX`/`MIN(so.final_total_amount)`, `SUM(soi.qty)`.
  - **Total sales**: net of refunds (same refund-subtraction pattern as `PaymentSalesReportService`), excludes voided (via `STATUS_FILTER`).
- `be/src/reports/dto/cashier-x-reading-response.dto.ts`
- `be/src/reports/mapper/cashier-x-reading-report.mapper.ts` — maps raw string/decimal rows to numbers via the existing `toDecimalNumber` helper pattern (see `sales-report.mapper.ts`).
- `be/src/reports/reports.interface.ts` — add raw row interfaces for the new queries, following `PaymentMethodSalesRawRow`/`SalesReportRawRow` conventions.

### Controller change

`be/src/reports/reports.controller.ts` — one new method:

```ts
@Get('cashier-x-reading')
@ApiOperation({ summary: 'Get current cashier\'s X Reading (today, self, own terminal)' })
@ApiOkResponse({ type: CashierXReadingResponseDto })
getCashierXReading(@CurrentUser() user: User): Promise<CashierXReadingResponseDto> {
  return this.cashierXReadingReportService.getReport(user);
}
```

### Response DTO shape

```ts
{
  cashierName: string;
  terminalName: string;          // currentUser.posTerminal?.legalName ?? currentUser.posTerminal?.kioskId ?? 'Unassigned'
  businessDate: string;          // today, formatted MM/DD/YYYY (DATE_FORMAT constant)
  reportGeneratedAt: string;     // ISO timestamp, "now"

  salesByPaymentMethod: { name: string; amount: number }[];  // Cash, Credit Card, GCash, + one row per distinct "Other" paymentMethodName
  totalSales: number;            // net of refunds, excludes voided

  totalTransactions: number;
  completedTransactions: number;
  voidedTransactions: number;
  refundedTransactions: number;  // orthogonal to status

  discounts: { name: string; amount: number }[];  // one row per discounts.name actually applied today
  totalDiscounts: number;

  vatSales: number;
  vatAmount: number;
  vatExemptSales: number;

  cashCollected: number;         // = the "Cash" entry in salesByPaymentMethod, also surfaced standalone for the receipt's "Cash Collected" line

  averageSale: number;
  highestSale: number;
  lowestSale: number;
  totalQuantitySold: number;
}
```

### Data contract example

```json
{
  "cashierName": "Juan Dela Cruz",
  "terminalName": "POS-01",
  "businessDate": "07/09/2026",
  "reportGeneratedAt": "2026-07-09T14:32:10.000Z",
  "salesByPaymentMethod": [
    { "name": "Cash", "amount": 12450.00 },
    { "name": "Credit Card", "amount": 4500.00 },
    { "name": "GCash", "amount": 2100.00 }
  ],
  "totalSales": 19050.00,
  "totalTransactions": 44,
  "completedTransactions": 42,
  "voidedTransactions": 1,
  "refundedTransactions": 1,
  "discounts": [
    { "name": "Senior Citizen / PWD", "amount": 620.00 },
    { "name": "KAPENA", "amount": 45.00 }
  ],
  "totalDiscounts": 665.00,
  "vatSales": 17000.89,
  "vatAmount": 2041.11,
  "vatExemptSales": 2008.00,
  "cashCollected": 12450.00,
  "averageSale": 453.57,
  "highestSale": 1250.00,
  "lowestSale": 85.00,
  "totalQuantitySold": 187
}
```

---

## Kiosk (`kiosk/`)

### New feature module `kiosk/lib/features/cashier_report/`

Follows the standard feature layout from `CLAUDE.md`:

```
cashier_report/
├── entities/
│   └── cashier_x_reading.dart        # immutable, @MappableClass; mirrors the BE DTO 1:1
├── repositories/
│   ├── cashier_report_repository.dart       # abstract: Future<CashierXReading> getXReading()
│   └── cashier_report_repository_impl.dart  # calls ReportsApi.getCashierXReading()
├── state/
│   └── cashier_x_reading_notifier.dart      # AsyncNotifier<CashierXReading?>, load()
├── use_cases/
│   └── encode_esc_pos_cashier_report.dart   # EncodeEscPosCashierReport, mirrors encode_esc_pos_receipt.dart
└── view/
    └── cashier_report_preview_screen.dart
```

- `kiosk/lib/data/backend_api/sources/reports_api.dart` — add `getCashierXReading()` hitting `GET /api/v1/reports/cashier-x-reading`.
- `kiosk/lib/data/backend_api/schemas/` — add `cashier_x_reading_dto.dart` (`@MappableClass`) for the raw JSON; a mapper extension converts it to the `CashierXReading` entity (same split other report types already use, e.g. `sales_summary_dto.dart` → `sales_summary.dart`).
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after adding the new `@MappableClass` files.

### Navigation

- New route file `kiosk/lib/navigation/cashier_report_route.dart` (`part of 'router.dart'`), registered alongside the others (`router.dart:23-33`):

  ```dart
  @TypedGoRoute<CashierReportRoute>(path: '/cashier-report')
  class CashierReportRoute extends GoRouteData with $CashierReportRoute {
    const CashierReportRoute();

    @override
    Widget build(BuildContext context, GoRouterState state) {
      return const CashierReportPreviewScreen();
    }
  }
  ```

### `transactions_screen.dart` change

`TopAppBar` **already has a `trailing` slot** (`kiosk/lib/widgets/top_app_bar.dart:13,21,92-96`) — no change needed to that widget. `transactions_screen.dart:67` becomes:

```dart
TopAppBar(
  title: 'Transactions',
  trailing: Consumer(
    builder: (context, ref, _) => _CashierReportButton(
      onTap: () async {
        await ref.read(cashierXReadingNotifierProvider.notifier).load();
        if (context.mounted) await const CashierReportRoute().push<void>(context);
      },
    ),
  ),
),
```

`_CashierReportButton` is a small new private widget in `transactions_screen.dart` (icon `Icons.receipt_long_rounded` + "Cashier Report" label, styled like the existing filled pill buttons elsewhere in the app) — per the approved mockup, it sits top-right in the app bar.

### Preview screen (`cashier_report_preview_screen.dart`)

Receipt-style layout (per approved mockup): a centered, max-width card on a `ColorSet.background` backdrop, scrollable, dashed section dividers, monospace-leaning aligned label/value rows — visually similar to whatever `ReceiptScreen` already does for its print preview (reuse styling/constants from there rather than re-inventing). Section order:

1. **Cashier Information** — Cashier Name, Terminal/Register, Business Date, Report Generated (date+time)
2. **Sales Summary** — one row per `salesByPaymentMethod` entry, then **Total Sales**
3. **Transaction Summary** — Total, Completed, Voided, Refunded
4. **Discount Summary** — one row per `discounts` entry, then **Total Discounts**
5. **Tax Summary** — VAT Sales, VAT Amount, VAT-Exempt Sales
6. **Cash Collected** — single line
7. **Other Summary** — Average Sale, Highest Sale, Lowest Sale, Total Quantity Sold

Sticky **"Print Report"** button pinned at the bottom (`POSColors`/`POSRadius` tokens, matches the rest of the app). The screen watches `cashierXReadingNotifierProvider` and renders loading/error/data states the same way `_TransactionsTable` already does (`transactions_screen.dart:388-455` is the reference pattern).

### Print integration

`encode_esc_pos_cashier_report.dart` — `EncodeEscPosCashierReport.call({required CashierXReading report})`, mirrors `encode_esc_pos_receipt.dart`: `Isolate.run`, `Generator(PaperSize.mm80, profile)`, `generator.text/row/feed/cut`. No logo/image block — this is an internal operational report, not a customer-facing receipt, so it opens directly with the "CASHIER REPORT (X READING)" header text. Riverpod provider `encodeEscPosCashierReportProvider`, same shape as `encodeEscPosReceiptProvider`.

The "Print Report" button on the preview screen calls a small `printCashierReport()` method (on the notifier or a dedicated print use case) that: encodes via `EncodeEscPosCashierReport`, sends via the existing `Win32PrinterTransport.sendData(...)`, guarded by the same `kIsWeb || !Platform.isWindows` check used in `ReceiptNotifier.print()` (`receipt_notifier.dart:30-39`).

**One model, two renderers**: the `CashierXReading` object fetched once by the notifier is what both the preview widget tree and the ESC/POS encoder read. No arithmetic happens on the kiosk — all numbers arrive pre-computed from the backend DTO.

---

## What Does NOT Change

- Checkout flow, payment processing, inventory, existing sales-order/refund/void business logic.
- Existing receipt printing/reprint flow (`ReceiptScreen`, `ReceiptNotifier`, `encode_esc_pos_receipt.dart`) — untouched, just used as a styling/pattern reference.
- `TransactionsScreen`'s table, pagination, search, void/refund actions.
- `PaymentMethod` enum, `Discount` entity/taxonomy, `SalesOrderStatus` enum — no migrations.
- `TopAppBar` widget itself (already supports `trailing`).
- The manager-facing analytics dashboard in `lib/features/reports/`.

## Testing

- **No new backend tests.** The entire `reports/` module (`total-report.service.ts`, `payment-sales-report.service.ts`, etc.) has zero existing spec coverage today — this feature follows that same pattern rather than introducing the module's first test file as a side effect.
- **One new kiosk test**: `test/features/cashier_report/state/cashier_x_reading_notifier_test.dart`, mirroring the existing `test/features/sales/state/ordering_notifier_test.dart` pattern — the one notifier-test precedent in this codebase.

## Out of Scope

- Any Z Reading / end-of-day reset flow.
- Opening float entry, drawer cash-count reconciliation, cash difference.
- Shift open/close tracking, shift numbers.
- Viewing another cashier's report, or a past business date's report.
- Adding Bank Transfer / Gift Certificate as first-class `PaymentMethod` enum values (today they'd only appear if logged via `Other` + a matching `paymentMethodName`).
- Categorizing discounts into Senior/PWD/Employee/Promo buckets.
