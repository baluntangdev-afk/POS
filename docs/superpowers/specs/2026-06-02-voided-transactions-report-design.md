# Voided Transactions in Sales Report

**Date:** 2026-06-02
**Branch:** feature/catalog_migration
**Status:** Approved

---

## Problem

The sales report (`GET /api/v1/reports`) does not surface voided (cancelled) transactions. Managers have no visibility into how many orders were voided or their total value within a date range. Additionally, this spec confirms the intended behaviour: net sales must only count `Confirmed` and `Completed` orders.

---

## Current Behaviour

- `VoidSalesOrderService` sets `status = 'Cancelled'` on a voided order and records `voidReason`, `voidedBy`, `voidedAt`.
- `reports.constants.ts` defines `STATUS_FILTER = [Confirmed, Completed]`.
- All report queries filter by `STATUS_FILTER`, so voided orders are already excluded from net sales — this is correct and must not change.
- `SalesResponseDto` (and the kiosk's `SalesSummaryDto`) have no voided fields whatsoever.

---

## Goal

Add `totalVoidedTransactions` and `totalVoidedAmount` to the sales summary report. Surface them as a metric card in the kiosk dashboard. Net sales continues to count only `Confirmed` and `Completed` orders.

---

## Approach: Extend the existing `/api/v1/reports` endpoint

Add the two voided fields to the existing `SalesResponseDto`. The `TotalReportService` runs a second parallel query scoped to `status = 'Cancelled'` within the same date window. The kiosk still makes one API call.

Rejected alternatives:
- New `/api/v1/reports/voided` endpoint — unnecessary network overhead and extra code surface.
- `?includeVoided=true` query flag — over-engineering; the kiosk always needs the data.

---

## Backend Changes (`be/`)

### 1. `src/reports/reports.interface.ts`

Add two optional fields to `SalesReportRawRow`:

```ts
totalVoidedTransactions?: string | number | null;
totalVoidedAmount?: string | number | null;
```

### 2. `src/reports/dto/sales-response.dto.ts`

Add two `@ApiProperty` fields:

```ts
totalVoidedTransactions: number;  // count of Cancelled orders in range
totalVoidedAmount: number;        // SUM(final_total_amount) of Cancelled orders
```

### 3. `src/reports/services/total-report.service.ts`

Add a third parallel query alongside the existing `soQueryBuilder` and `soiQueryBuilder`:

```ts
const voidedQueryBuilder = this.salesOrderRepository
  .createQueryBuilder('so')
  .select('COUNT(so.id)', 'totalVoidedTransactions')
  .addSelect('SUM(so.final_total_amount)', 'totalVoidedAmount')
  .andWhere("so.status = :voidedStatus", { voidedStatus: SalesOrderStatus.CANCELLED });
// apply same date filter (so_date)
```

The date filter helper (`applyDateFilter`) currently injects `STATUS_FILTER`; the new query bypasses that and uses its own `WHERE status = 'Cancelled'`. Extract or duplicate the date-only part of the filter for the voided query.

Combine all three results in `getReport()` before passing to the mapper.

### 4. `src/reports/mapper/sales-report.mapper.ts`

Map the two new fields with the same 0-safe `toDecimalNumber` helper:

```ts
totalVoidedTransactions: toDecimalNumber(raw.totalVoidedTransactions),
totalVoidedAmount: toDecimalNumber(raw.totalVoidedAmount),
```

Also update the null-path fallback to include `totalVoidedTransactions: 0, totalVoidedAmount: 0`.

---

## Kiosk Changes (`kiosk/`)

### 5. `lib/data/backend_api/schemas/sales_summary_dto.dart`

Add two new required fields to `SalesSummaryDto`:

```dart
final double totalVoidedAmount;
final int totalVoidedTransactions;
```

Re-run `build_runner` to regenerate `sales_summary_dto.mapper.dart`.

### 6. `lib/features/reports/entities/sales_summary.dart`

Mirror the same two fields on the `SalesSummary` entity.

Re-run `build_runner` to regenerate `sales_summary.mapper.dart`.

### 7. `lib/features/reports/mappers/sales_summary_mappers.dart`

Pass through the two new fields in both `toEntity` and `toModel` extensions.

### 8. `lib/features/reports/state/sales_report_state.dart`

Add two computed getters:

```dart
double get totalVoidedAmount =>
    salesSummary?.totalVoidedAmount ?? 0.0;

int get totalVoidedTransactions =>
    salesSummary?.totalVoidedTransactions ?? 0;
```

### 9. `lib/features/reports/view/sales_report_screen.dart`

Add a "Voided" metric card at the end of `_buildMetrics()`:

```dart
Metric(
  title: 'Voided',
  value: state.totalVoidedTransactions.toString(),
  icon: Icons.block_rounded,
  color: Color(0xFFEF4444),  // red — matches existing Refunds colour
  isMonetary: false,
),
```

The metric displays the count of voided transactions. `totalVoidedAmount` is available in state for any future tooltip or drill-down without requiring another API call.

> The Windows dashboard currently lays out 5 metric cards in a single `Row` with `Expanded` children. Adding a 6th card will automatically fit within the same layout — each card shrinks proportionally.

---

## Data Contract

`GET /api/v1/reports?startDate=...&endDate=...` response shape after this change:

```json
{
  "totalSales": 15000.00,
  "totalDiscount": 500.00,
  "totalRefunds": 200.00,
  "totalItems": 120,
  "totalTransactions": 45,
  "totalVoidedTransactions": 3,
  "totalVoidedAmount": 1200.00
}
```

---

## What Does NOT Change

- `STATUS_FILTER` remains `[Confirmed, Completed]` — net sales is unaffected.
- All other report endpoints (hourly, daily, monthly, product, user, payment) are unaffected.
- No DB migration required — `status` column and `voided_*` columns already exist.
- No new API route.

---

## Out of Scope

- Drill-down list of individual voided transactions (separate feature).
- Voided breakdown on the `sales_health_page` grouped reports.
- Displaying `totalVoidedAmount` as a second line on the metric card (can be added later without backend changes).
