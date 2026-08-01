# Cashier Daily Report — Design Spec

**Date:** 2026-07-10
**Status:** Approved

## Summary

A new "Cashier Daily Report" screen in the kiosk, opened from the existing (currently inert)
`Cashier Daily Report` button on the Transactions screen. It renders a BIR-style cashier report
for the **logged-in cashier's own transactions today**, matching the printed receipt layout the
business uses today (see `7fa0b95e-66ce-480c-a392-22e7f5b0f77f.jpg`): summary totals, an
**itemized SALES BY PRODUCT breakdown**, and a cash ledger. The screen can print the report to
the receipt printer via ESC/POS, same as the X-Reading.

## Decisions (from brainstorming)

- **Data scope:** current cashier, today only — identical scoping rules to the X-Reading
  (`created_by = cashier`, `so_date::date = CURRENT_DATE`, `status IN (CONFIRMED, COMPLETED)`,
  refunds netted out, voided excluded).
- **Layout:** follows the screenshot's document structure, not the X-Reading's sections.
- **Printing:** yes — preview screen with a "Print Cashier Report" button (ESC/POS, mm80).
- **Change fund:** omitted for now (no drawer/shift concept exists). Cash ledger lists cash
  payments and a TOTAL CASH line only.
- **Zero Rated Sales:** not tracked by the system; reported as a constant `0` to keep the fixed
  BIR layout.
- **"No. Customers"** from the sample receipt is dropped (not tracked); transaction count covers it.

## Report content

```
CASHIER REPORT
<terminal>            <business date>
                      <cashier name>
--------------------------------
Gross Sales                 #,##0.00

Summary:
  Vatable Sales             #,##0.00   (VAT-exclusive sales of non-exempt orders)
  VAT Amount                #,##0.00
  VAT Exempt Sales          #,##0.00
  Zero Rated Sales              0.00   (always 0)

Others:
  Net of Tax                #,##0.00   (grossSales − vatAmount)
  No. Transactions                 N   (completed transactions)
  Total Quantity                   N   (sum of item qty)

Total Cash Sales            #,##0.00   (sum of Cash payments)
No. Cash Sales                     N   (count of Cash payments)

SALES BY PRODUCT
QTY x PRODUCT                 AMOUNT
--------------------------------
 <qty> <product name>       #,##0.00   (alphabetical by name, add-ons included)
 ...
--------------------------------
TOTAL                       #,##0.00   (sum of product amounts)

CASH LEDGER
<hh:mm a>  CASH[#ref]       #,##0.00   (one row per cash payment, oldest first)
***** TOTAL CASH            #,##0.00
```

## Architecture (Approach A — new dedicated endpoint + parallel feature slice)

Mirrors the X-Reading implementation end to end; the two reports stay independent.

### Backend (`be/src/reports/`)

- **`GET /api/v1/reports/cashier-daily-report`** (JWT, `@CurrentUser()`), returns
  `CashierDailyReportResponseDto`.
- **`dto/cashier-daily-report-response.dto.ts`** — `CashierDailyReportResponseDto` with
  `cashierName`, `terminalName`, `businessDate`, `reportGeneratedAt`, `grossSales`,
  `vatableSales`, `vatAmount`, `vatExemptSales`, `zeroRatedSales`, `netOfTax`,
  `transactionCount`, `totalQuantity`, `totalCashSales`, `cashSalesCount`,
  `salesByProduct: ProductSalesLineDto[]` (`quantity`, `productName`, `amount`),
  `cashLedger: CashLedgerEntryDto[]` (`time`, `reference`, `amount`).
- **`services/cashier-daily-report.service.ts`** — extends `BaseReportService<User, …>`;
  parallel queries reusing the X-Reading query shapes plus two new ones:
  - *sales by product:* `so_items` joined to `sales_orders`, grouped by `soi.description`,
    `SUM(soi.qty)` and `SUM(soi.item_total_amount)`, `ORDER BY LOWER(soi.description)`.
    Add-on lines are included (they appear on the sample receipt).
  - *cash sales:* `payments` filtered to `payment_method = PaymentMethod.CASH`:
    sum + count, and itemized rows (date, reference, amount) for the ledger.
- **`mapper/cashier-daily-report.mapper.ts`** — pure static mapper; all amounts default to 0
  on empty query results (same convention as `CashierXReadingReportMapper`).
  `netOfTax = grossSales − vatAmount`; `zeroRatedSales = 0`.
- Raw-row interfaces added to `reports.interface.ts`; service registered in `reports.module.ts`
  and controller.

### Kiosk (`kiosk/lib/`)

Extends the existing `features/cashier_report/` module:

- `data/backend_api/schemas/cashier_daily_report_dto.dart` (+ generated `.mapper.dart`)
- `ReportsApi.getCashierDailyReport()`
- `features/cashier_report/entities/cashier_daily_report.dart` (+ generated mapper)
- `features/cashier_report/mappers/cashier_daily_report_mappers.dart` (DTO → entity)
- `CashierReportRepository.getDailyReport()` on the existing repository
- `features/cashier_report/state/cashier_daily_report_notifier.dart` — same load/print pattern
  as `CashierXReadingNotifier`
- `features/cashier_report/use_cases/encode_esc_pos_cashier_daily_report.dart` — ESC/POS layout
  matching the report content above (mm80, qty column + wrapped name + right-aligned amount)
- `features/cashier_report/view/report_preview_widgets.dart` — the receipt-preview building
  blocks currently private to `cashier_report_preview_screen.dart` (store header, section,
  amount/count/key-value rows, dashed divider, error view) extracted so both screens share them;
  the X-Reading preview screen is refactored to consume them with no visual change.
- `features/cashier_report/view/cashier_daily_report_screen.dart` — receipt-style preview +
  "Print Cashier Report" button
- `navigation/cashier_daily_report_route.dart` (`/cashier-daily-report`) + `router.dart` part
- `_CashierDailyReportButton` in `transactions_screen.dart` wired like the X-Reading button
  (spinner while loading, then push route)

### Edge cases

- No transactions today → all zeros, empty product list and ledger; screen still renders.
- Non-Windows / web → print is a no-op (same guard as X-Reading).
- Amounts are `double` end to end in DTOs (matches X-Reading), formatted with peso formatting
  in the UI and `#,##0.00` in ESC/POS.

### Testing

- Backend: unit spec for `CashierDailyReportMapper` (pure — grouping already done in SQL;
  verifies defaults-to-zero, netOfTax arithmetic, ledger mapping).
- Kiosk: `cashier_daily_report_notifier_test.dart` mirroring the existing X-Reading notifier
  test (load success + error), plus a DTO→entity mapper test.
