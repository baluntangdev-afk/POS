# Phase 4 — Sales Reports Depth (Charts + Export) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give mobile's existing summary-cards-only Reports screen the same visual depth as kiosk's Sales Health page (donut charts for payment/cashier/category breakdowns, a bar chart for sales-over-time) plus a CSV export/share action — all computed locally, since (per research) kiosk's equivalent feature is 100% backend-driven with no local SQL to port.

**Architecture:** Add a new "Sales Health" tab to the existing `ReportsScreen` (mirroring kiosk's `ReportTabSelector` two-tab layout), rendering `fl_chart` donut charts (already a dependency, currently unused anywhere in mobile) fed by the existing `getPaymentBreakdown`/`getSalesByCashier` DAO methods plus one new "sales by category" method, and a bar chart fed by one new time-bucketed-series DAO method. A `ReportExportService` builds a CSV (using the already-present `csv` package) and shares it via `share_plus` (also already present, unused) — no PDF/Excel, no new dependency.

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), Drift (sqlite), `fl_chart` (existing dep), `csv` (existing dep), `share_plus` (existing dep).

---

## Design Decisions (made without a user round-trip, documented for review)

1. **CSV export, not XLSX.** Kiosk exports `.xlsx` via the `excel` package. Mobile already depends on `csv` (used for import) and has no `excel` dependency. Adding a whole new spreadsheet-format package to match kiosk exactly would be pure format-parity for its own sake — a CSV covers the same "get the numbers into a spreadsheet" need with a dependency mobile already has.
2. **Share-sheet, not a Downloads-folder file save.** Kiosk (a Windows desktop app) saves to `%USERPROFILE%\Downloads`. Mobile is a phone/tablet app — the platform-idiomatic equivalent is Android's share sheet (`share_plus`, already a dependency, currently unused), which lets the user save/email/send the file wherever they want, not a hardcoded folder that may not be user-visible on Android.
3. **No "unexported day" auto-reminder dialog.** Kiosk's mechanism is entirely backend-tracked (`GET /reports/exportable`, `PATCH /reports/mark-exported` — a server-side "has this day's data been exported yet" flag with no local analog). Building a local equivalent would mean adding a new persisted table just to track export status per day — a real feature in its own right, not a natural fit for "reports depth," and not requested by name in the parent plan's Phase 4 scope bullet ("file export" — the reminder was an implementation detail of kiosk's specific backend, not a stated requirement). This plan ships an on-demand "Export CSV" button instead. If the reminder is wanted later, it's a follow-up.

---

## Task 1: New `SalesDao` methods — sales-by-category and time-bucketed series

**Files:**
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`
- Test: `mobile/test/core/database/daos/sales_dao_reports_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/core/database/daos/sales_dao_reports_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedGroup(String name) =>
      db.productsDao.insertProductGroup(ProductGroupsTableCompanion.insert(name: name));
  Future<int> _seedProduct(int groupId, String name, double price) =>
      db.productsDao.insertProduct(ProductsTableCompanion.insert(groupId: groupId, name: name, price: price));
  Future<int> _seedSale(double total, DateTime createdAt) =>
      db.salesDao.insertSale(SalesTableCompanion.insert(
          total: total, type: 'dine_in', status: 'completed', createdAt: createdAt));
  Future<void> _seedSaleItem(int saleId, int productId, int qty, double unitPrice) =>
      db.salesDao.insertSaleItem(SaleItemsTableCompanion.insert(
          saleId: saleId, productId: productId, qty: qty, unitPrice: unitPrice));

  test('getSalesByProductGroup sums sale-item revenue grouped by category', () async {
    final drinksId = await _seedGroup('Drinks');
    final foodId = await _seedGroup('Food');
    final latteId = await _seedProduct(drinksId, 'Latte', 100);
    final burgerId = await _seedProduct(foodId, 'Burger', 150);

    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);
    final saleId = await _seedSale(250, DateTime(2026, 1, 1, 10));
    await _seedSaleItem(saleId, latteId, 1, 100);
    await _seedSaleItem(saleId, burgerId, 1, 150);

    final breakdown = await db.salesDao.getSalesByProductGroup(from, to);

    expect(breakdown, hasLength(2));
    expect(breakdown.firstWhere((r) => r.groupName == 'Drinks').total, 100);
    expect(breakdown.firstWhere((r) => r.groupName == 'Food').total, 150);
  });

  test('getSalesTimeSeries buckets completed sales totals by day', () async {
    final groupId = await _seedGroup('Drinks');
    await _seedProduct(groupId, 'Latte', 100);

    await _seedSale(100, DateTime(2026, 1, 1, 9));
    await _seedSale(50, DateTime(2026, 1, 1, 15));
    await _seedSale(75, DateTime(2026, 1, 2, 10));

    final series = await db.salesDao.getSalesTimeSeries(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 3),
      granularity: 'day',
    );

    expect(series, hasLength(2));
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01').total, 150);
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-02').total, 75);
  });

  test('getSalesTimeSeries buckets by hour when granularity is hour', () async {
    final groupId = await _seedGroup('Drinks');
    await _seedProduct(groupId, 'Latte', 100);

    await _seedSale(100, DateTime(2026, 1, 1, 9, 15));
    await _seedSale(50, DateTime(2026, 1, 1, 9, 45));
    await _seedSale(75, DateTime(2026, 1, 1, 14, 0));

    final series = await db.salesDao.getSalesTimeSeries(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      granularity: 'hour',
    );

    expect(series, hasLength(2));
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01 09').total, 150);
    expect(series.firstWhere((r) => r.bucketLabel == '2026-01-01 14').total, 75);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_reports_test.dart`
Expected: FAIL — methods don't exist.

- [ ] **Step 3: Add two methods + two DTOs to `SalesDao`**

Add near the other small DTO classes (`StatusCounts`, `CashierSales`, `CashLedgerRow`):

```dart
class ProductGroupSales {
  final String groupName;
  final double total;
  const ProductGroupSales({required this.groupName, required this.total});
}

class TimeSeriesPoint {
  final String bucketLabel;
  final double total;
  const TimeSeriesPoint({required this.bucketLabel, required this.total});
}
```

Add methods (near `getSalesByCashier`):

```dart
  Future<List<ProductGroupSales>> getSalesByProductGroup(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT pg.name as group_name, COALESCE(SUM(si.qty * si.unit_price), 0) as total '
      'FROM sale_items si '
      'JOIN products p ON p.id = si.product_id '
      'JOIN product_groups pg ON pg.id = p.group_id '
      'JOIN sales s ON s.id = si.sale_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY pg.id, pg.name',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, saleItemsTable, productsTable, productGroupsTable},
    ).get();
    return rows
        .map((r) => ProductGroupSales(
              groupName: r.read<String>('group_name'),
              total: r.read<double>('total'),
            ))
        .toList();
  }

  Future<List<TimeSeriesPoint>> getSalesTimeSeries(
    DateTime from,
    DateTime to, {
    required String granularity,
  }) async {
    final format = switch (granularity) {
      'hour' => '%Y-%m-%d %H',
      'month' => '%Y-%m',
      _ => '%Y-%m-%d',
    };
    final rows = await customSelect(
      "SELECT strftime('$format', s.created_at, 'unixepoch') as bucket, COALESCE(SUM(s.total), 0) as total "
      'FROM sales s '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      "GROUP BY strftime('$format', s.created_at, 'unixepoch') ORDER BY bucket",
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable},
    ).get();
    return rows
        .map((r) => TimeSeriesPoint(
              bucketLabel: r.read<String>('bucket'),
              total: r.read<double>('total'),
            ))
        .toList();
  }
```

**Note:** the `strftime(..., 'unixepoch')` pattern mirrors `getCashLedgerForDateRangeAndCashier`'s already-proven `date(s.created_at, 'unixepoch')` approach from Phase 2 (confirmed empirically correct there) — same unix-seconds storage assumption, just a different `strftime` format string per granularity. The format string is interpolated directly into the SQL string (not parameterized) since it's a fixed, internally-controlled enum-like value (`'hour'|'day'|'month'` via the `switch`), never user input — this is safe, not a SQL-injection risk, since `granularity` only ever comes from hardcoded call sites in this codebase, not free-text user input. If a future caller ever threads raw user text into `granularity`, that would need to change to a strict allowlist check first, but for now the `switch` expression itself already only produces one of three fixed literal strings.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_reports_test.dart`
Expected: PASS (all 3 tests)

---

## Task 2: Sales Health tab — donut charts (payment, cashier, category)

**Files:**
- Create: `mobile/lib/features/reports/entities/sales_health_data.dart`
- Create: `mobile/lib/features/reports/state/sales_health_notifier.dart`
- Create: `mobile/lib/features/reports/view/sales_health_tab.dart`
- Create: `mobile/lib/features/reports/view/sales_donut_chart.dart`
- Modify: `mobile/lib/features/reports/view/reports_screen.dart` (add a two-tab layout: "Overview" [existing content] / "Sales Health" [new])
- Test: `mobile/test/features/reports/state/sales_health_notifier_test.dart`

`SalesHealthData` (plain class): `paymentBreakdown: List<PaymentBreakdown>` (reuse existing type from `report_data.dart`), `salesByCashier: List<CashierSales>` (reuse the `SalesDao.CashierSales` DTO directly — it's already a small, stable, read-only shape; no need for a separate feature-local wrapper here, unlike Phase 2's `CashLedgerEntry` precedent, since this one has no JSON-persistence round-trip to worry about), `salesByCategory: List<ProductGroupSales>` (reuse the new DAO DTO directly, same reasoning), `from`/`to`.

`SalesHealthNotifier extends AsyncNotifier<SalesHealthData>` — holds its OWN period/date-range state, independent from `ReportsNotifier`'s (mirrors kiosk's `healthPageDateFilter` being separate from the dashboard tab's filter — confirmed in research). `build()`/`_load()` calls `db.salesDao.getPaymentBreakdown(from, to)` (mapped into `PaymentBreakdown` with a percentage computed client-side: `total / totalOfAll * 100`, matching kiosk's approach — the raw DAO method returns `List<Map<String,Object?>>`, not `PaymentBreakdown` objects directly; check `ReportsNotifier`'s existing `_load()` for how it already maps this raw shape into `PaymentBreakdown` and reuse that exact mapping logic rather than re-deriving it, to avoid two slightly-different percentage formulas existing in the codebase), `getSalesByCashier(from, to)`, `getSalesByProductGroup(from, to)` (new, Task 1). Exposes `setPeriod`/`refresh`, same conventions as `ReportsNotifier`.

`SalesDonutChart` (reusable `StatelessWidget`): takes a `title`, a `List<({String label, double value})>` (or reuse `PaymentBreakdown`/`CashierSales`/`ProductGroupSales` directly via three thin call-site adapters rather than forcing a generic tuple type — implementer's choice, prefer whichever is less boilerplate at the three call sites), renders `fl_chart`'s `PieChart(PieChartData(sections: [...]))` with a `sectionsSpace: 2`, a fixed rotating color palette (reuse `AppColors` tokens where sensible, e.g. `[AppColors.primary, AppColors.secondary, AppColors.success, AppColors.warning, AppColors.error, AppColors.textSecondary]` cycling by index — mirrors kiosk's fixed-palette approach), percentage labels on each `PieChartSectionData.title`, plus a manual legend list below the chart. Empty state: an icon + "No data available" (mirror kiosk's).

`SalesHealthTab`: three `SalesDonutChart` instances stacked in a scrollable column (phone-first, no need for kiosk's responsive-wrap-2-per-row grid unless `context.responsive` makes it trivial — check the existing `context.responsive.value(...)` helper used elsewhere in mobile and use it if a 2-per-row-on-tablet layout is genuinely simple to add, otherwise a single column is acceptable and simpler), each fed by `salesHealthProvider`, with its own small period selector (reuse or closely mirror `reports_screen.dart`'s existing `_PeriodSelector` chip-row widget rather than inventing a new one — check whether it's easily reusable/extractable as a shared widget, or just duplicate the small chip-row if extraction would touch already-approved code unnecessarily).

- [ ] **Step 1: Write the failing notifier test** — seed sales with different payment methods/cashiers/categories, assert `salesHealthProvider` returns correctly-shaped breakdowns for all three.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Implement `SalesHealthData`, `SalesHealthNotifier`.**
- [ ] **Step 4: Run test to verify it passes.**
- [ ] **Step 5: Build `SalesDonutChart`, `SalesHealthTab`.**
- [ ] **Step 6: Wire a two-tab `TabBar`/`TabBarView` into `ReportsScreen`** (read the current file in full first — it currently has no tabs at all, just a single scrollable body; wrap the existing body as "Overview" tab content, add "Sales Health" as the second tab, using a standard `DefaultTabController`/`TabBar` — don't invent a custom tab-selector widget when Flutter's built-in one is a direct fit).
- [ ] **Step 7: `dart analyze` clean.**

---

## Task 3: Bar chart — sales over time

**Files:**
- Create: `mobile/lib/features/reports/view/sales_bar_chart.dart`
- Modify: `mobile/lib/features/reports/state/sales_health_notifier.dart` (add a `granularity` field: hour/day/month, and a `timeSeries: List<TimeSeriesPoint>` field on `SalesHealthData`, computed via the new `getSalesTimeSeries` from Task 1)
- Modify: `mobile/lib/features/reports/view/sales_health_tab.dart` (add the bar chart above or below the three donut charts, with a granularity selector: Hourly/Daily/Monthly chips)
- Test: extend `mobile/test/features/reports/state/sales_health_notifier_test.dart`

`SalesBarChart` (`StatelessWidget`): takes `List<TimeSeriesPoint>`, renders `fl_chart`'s `BarChart(BarChartData(...))` with one `BarChartGroupData` per point, a single-color palette (or the same rotating palette as the donuts, implementer's choice — kiosk rotates 4 colors per bar; a single consistent bar color is equally valid and simpler, prefer simplicity unless the rotating-color look is trivial to add), touch tooltips showing the exact value (`BarTouchData(touchTooltipData: BarTouchTooltipData(...))`), and reasonably-spaced X-axis labels (if there are more than ~8 buckets, skip labels for some of them to avoid overlap — a simple modulo-based skip is sufficient, no need for kiosk's more elaborate dynamic-interval logic).

- [ ] **Step 1: Extend the failing test** — assert `salesHealthProvider`'s `timeSeries` field reflects the seeded data for a given granularity; assert `setGranularity('hour')`/`setGranularity('day')` reloads with the right bucketing.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Extend `SalesHealthNotifier` with `granularity` state + `setGranularity` method.**
- [ ] **Step 4: Run test to verify it passes.**
- [ ] **Step 5: Build `SalesBarChart`, wire into `SalesHealthTab` with a granularity chip-selector.**
- [ ] **Step 6: `dart analyze` clean.**

---

## Task 4: CSV export + share

**Files:**
- Create: `mobile/lib/core/services/report_export_service.dart`
- Modify: `mobile/lib/features/reports/view/reports_screen.dart` (add an export `IconButton` to the app bar)
- Test: `mobile/test/core/services/report_export_service_test.dart`

`ReportExportService.exportToCsv(ReportData report)` (static method): builds rows using the `csv` package's `ListToCsvConverter` — a header/summary section (Total Sales, Transaction Count, Average Order, date range), a blank row, a "Payment Breakdown" section (method, total, %), a blank row, a "Top Products" section (name, qty, total) — mirrors kiosk's multi-section XLSX sheet structure but flattened into one CSV with section headers, since CSV has no multi-sheet concept. Writes the resulting string to a temp file (`(await getTemporaryDirectory()).path/sales_report_<date>.csv`, using `path_provider` — already a direct dependency per Phase 3), then calls `Share.shareXFiles([XFile(path)], text: 'Sales report for ...')` from `share_plus`.

In `reports_screen.dart`: add an `IconButton` (`Icons.ios_share`/`Icons.file_download_outlined`) in the app bar, calling `ReportExportService.exportToCsv(currentReportData)` for whichever period is currently selected on the Overview tab, with a loading indicator while the file is built and a `SnackBar` on completion/error (mirror the confirm/feedback pattern established in earlier phases — no confirm dialog needed here since export is non-destructive, just a direct action).

- [ ] **Step 1: Write the failing test** — build a small `ReportData` fixture, call `exportToCsv`, assert the returned/written file exists and its content contains expected section headers and values (parse it back with `csv`'s `CsvToListConverter` to assert structure, rather than fragile exact-string matching).
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Implement `ReportExportService.exportToCsv`.**
- [ ] **Step 4: Run test to verify it passes.**
- [ ] **Step 5: Wire the export button into `ReportsScreen`.**
- [ ] **Step 6: `dart analyze` clean across the whole `reports` feature.**

---

## Task 5: Manual verification pass for Phase 4

- [ ] **Step 1: Run full mobile test suite** — `cd mobile && fvm flutter test` — all pass except the known pre-existing unrelated `widget_test.dart` failure.
- [ ] **Step 2: Run the app and walk the golden path:**
  1. Complete a few sales across different payment methods, cashiers, and product categories.
  2. Dashboard → Sales Reports → Overview tab (unchanged) → Sales Health tab — confirm all three donut charts render with correct percentages/legends, and the bar chart renders with correct bucketed totals; switch Hourly/Daily/Monthly and confirm the bars re-bucket correctly.
  3. Tap the export button on the Overview tab — confirm a CSV is generated and the platform share sheet opens; open the shared file (e.g. via a file manager or email-to-self) and confirm the CSV content matches what's shown on screen.
  4. Confirm no auto-popup "unexported day" reminder appears anywhere (intentionally not built — verify nothing unexpected happens on app launch/report screen entry).

If any step fails, use `superpowers:systematic-debugging` before patching.

---

## Self-Review Notes

- **Spec coverage:** Parent plan's Phase 4 bullets (charting package check — confirmed `fl_chart` already present and unused, by-cashier/by-group breakdowns extending `ReportsNotifier`/`ReportData` — done via a sibling `SalesHealthNotifier` rather than bloating the existing notifier, a file-export action with a platform decision — decided: CSV + share_plus, not a Windows-style Downloads save) are all covered by Tasks 1-4.
- **No blind trust in memory-only claims:** Task 2 explicitly instructs reading `ReportsNotifier`'s existing payment-breakdown percentage-mapping logic before re-deriving it, to avoid two divergent formulas; Task 1's `strftime`/`unixepoch` approach is explicitly justified by referencing Phase 2's already-empirically-verified identical pattern rather than assuming it works.
- **Known scope decision, not a gap:** the "unexported day" reminder is deliberately not built (Design Decision #3) — this is a backend-coupled feature of kiosk with no clean local-first equivalent, not an oversight.
