# Phase 2 — Cashier Accounting (X-Reading, Z-Reading, Daily Report) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the mobile app shift-close-out capability equivalent to kiosk's Cashier Reports: X-Reading (per-cashier unclosed snapshot), Cashier Daily Report (per-cashier daily summary), and Z-Reading (store-wide, supervisor-authorized close), each closeable, persisted, reprint-able, and ESC/POS printable — computed entirely from mobile's local Drift database, since (per research) kiosk's equivalent logic lives entirely on a remote backend with no local SQL to port.

**Architecture:** Three new Drift tables (`x_readings`, `daily_reports`, `z_readings`) persist a snapshot at close time — closing scopes "the next period" to start where the last close left off, matching kiosk's "unreported window" semantics. New aggregation queries are added to `SalesDao` (status counts, refund sums, per-cashier grouping). Three new feature packages (`features/cashier_accounting/{x_reading,daily_report,z_reading}`) each follow the established `AsyncNotifier` + `HookConsumerWidget` + plain-class-entity pattern from `features/reports/`. Printing extends the existing `PrintService` (Bluetooth ESC/POS, `esc_pos_utils_plus` + `print_bluetooth_thermal`) with three new byte-building methods, mirroring kiosk's section-header/amount-row helpers. VAT is approximated by applying `store_info.taxRate` to totals (no per-sale tax field exists). Cash beginning/ending balance is a manual number entry captured at close time (no cash-drawer hardware integration).

**Tech Stack:** Flutter, Riverpod (`hooks_riverpod`), `go_router`, Drift (sqlite) with a schema migration, `esc_pos_utils_plus` + `print_bluetooth_thermal` (already dependencies).

---

## Design Decisions (confirmed with user before writing this plan)

1. **Persisted closes, not read-only reports.** Closing any of the three report types writes a row to its table and the next report starts from `periodEnd` of the last closed row of that same type (scoped per-cashier for X-Reading/Daily Report, store-wide for Z-Reading). This requires a schema migration (`schemaVersion` 1 → 2).
2. **VAT and cash balance are approximated/manual, not omitted.** VAT split = `store_info.taxRate` applied to `totalSales` (not a true per-item breakdown, since no per-sale tax column exists). Cash beginning/ending balance is a plain numeric text-field entry the cashier types in at close time — not derived from any cash-drawer integration (none exists).
3. **List-shaped breakdowns are stored as JSON text columns**, not normalized junction tables — each closed reading is an immutable point-in-time snapshot that's only ever read back whole (for reprint/history), never queried by sub-field, so normalizing would be pure overhead (YAGNI).
4. **"Cashier" = the currently logged-in `UsersTable` row.** No separate cashier/shift-session table — matches both kiosk's model and mobile's existing Phase-1 `cashierId` usage on `sales_table`.

---

## Task 1: Schema migration — three new tables

**Files:**
- Create: `mobile/lib/core/database/tables/x_readings_table.dart`
- Create: `mobile/lib/core/database/tables/daily_reports_table.dart`
- Create: `mobile/lib/core/database/tables/z_readings_table.dart`
- Modify: `mobile/lib/core/database/app_database.dart` (register tables, bump `schemaVersion`, add migration step)
- Test: `mobile/test/core/database/schema_migration_test.dart`

### `x_readings_table.dart`

```dart
import 'package:drift/drift.dart';

class XReadingsTable extends Table {
  @override
  String get tableName => 'x_readings';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer()();
  TextColumn get cashierName => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  RealColumn get totalSales => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get voidedCount => integer()();
  IntColumn get refundedCount => integer()();
  TextColumn get paymentBreakdownJson => text()();
  TextColumn get topProductsJson => text()();
}
```

### `daily_reports_table.dart`

```dart
import 'package:drift/drift.dart';

class DailyReportsTable extends Table {
  @override
  String get tableName => 'daily_reports';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer()();
  TextColumn get cashierName => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  RealColumn get grossSales => real()();
  RealColumn get vatableSales => real()();
  RealColumn get vatAmount => real()();
  RealColumn get vatExemptSales => real()();
  RealColumn get netOfTax => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get totalQtySold => integer()();
  RealColumn get cashSalesTotal => real()();
  IntColumn get cashSalesCount => integer()();
  TextColumn get salesByProductJson => text()();
  TextColumn get cashLedgerJson => text()();
}
```

### `z_readings_table.dart`

```dart
import 'package:drift/drift.dart';

class ZReadingsTable extends Table {
  @override
  String get tableName => 'z_readings';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get zCounter => integer()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  DateTimeColumn get generatedAt => dateTime()();
  IntColumn get closedByUserId => integer()();
  TextColumn get closedByName => text()();
  IntColumn get authorizedByUserId => integer()();
  TextColumn get authorizedByName => text()();
  RealColumn get beginningBalance => real()();
  RealColumn get endingBalance => real()();
  RealColumn get totalSales => real()();
  RealColumn get vatableSales => real()();
  RealColumn get vatAmount => real()();
  RealColumn get vatExemptSales => real()();
  IntColumn get transactionCount => integer()();
  IntColumn get completedCount => integer()();
  IntColumn get voidedCount => integer()();
  IntColumn get refundedCount => integer()();
  RealColumn get discountTotal => real()();
  RealColumn get cashCollected => real()();
  IntColumn get totalQtySold => integer()();
  TextColumn get paymentBreakdownJson => text()();
  TextColumn get salesByCashierJson => text()();
}
```

### Migration in `app_database.dart`

Current state (confirmed): `@DriftDatabase(tables: [UsersTable, ProductGroupsTable, ProductsTable, ModifierGroupsTable, ModifierOptionsTable, SalesTable, SaleItemsTable, SaleItemModifiersTable, PaymentsTable, RefundsTable, RefundItemsTable, StoreInfoTable], daos: [UsersDao, ProductsDao, SalesDao, StoreInfoDao])`, `schemaVersion = 1`, single `onCreate: (m) async { await m.createAll(); await storeInfoDao.ensureStoreInfoExists(); }`.

- [ ] **Step 1: Write the failing migration test**

```dart
// mobile/test/core/database/schema_migration_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  test('schemaVersion is 2 and new tables exist', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 2);

    await db.into(db.xReadingsTable).insert(XReadingsTableCompanion.insert(
          cashierId: 1,
          cashierName: 'Test Cashier',
          periodStart: DateTime(2026, 1, 1),
          periodEnd: DateTime(2026, 1, 2),
          generatedAt: DateTime(2026, 1, 2),
          totalSales: 100,
          transactionCount: 1,
          voidedCount: 0,
          refundedCount: 0,
          paymentBreakdownJson: '[]',
          topProductsJson: '[]',
        ));
    final xReadings = await db.select(db.xReadingsTable).get();
    expect(xReadings, hasLength(1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd mobile && flutter test test/core/database/schema_migration_test.dart`
Expected: FAIL — `xReadingsTable` getter doesn't exist on `AppDatabase` yet.

- [ ] **Step 3: Add the three tables to `AppDatabase` and bump schema version**

In `mobile/lib/core/database/app_database.dart`:
1. Add imports for the three new table files.
2. Add `XReadingsTable, DailyReportsTable, ZReadingsTable` to the `tables:` list in `@DriftDatabase(...)`.
3. Change `schemaVersion` from `1` to `2`.
4. Update the `migration` getter (find the existing `MigrationStrategy migration` — if none exists yet beyond `onCreate`, add one) to include an `onUpgrade` step:

```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await storeInfoDao.ensureStoreInfoExists();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(xReadingsTable);
            await m.createTable(dailyReportsTable);
            await m.createTable(zReadingsTable);
          }
        },
      );
```

(If `MigrationStrategy`/`migration` getter already exists in some other shape, adapt this into it rather than duplicating — read the file first.)

- [ ] **Step 4: Regenerate Drift code**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd mobile && flutter test test/core/database/schema_migration_test.dart`
Expected: PASS

---

## Task 2: New `SalesDao` aggregation queries needed by all three reports

**Files:**
- Modify: `mobile/lib/core/database/daos/sales_dao.dart`
- Test: `mobile/test/core/database/daos/sales_dao_accounting_test.dart`

Existing date-range aggregations (`getTotalSalesForDateRange`, `getPaymentBreakdown`, `getTopProducts`, `getTransactionCountForDateRange`) all filter `status = 'completed'` only. The reports need void/refund counts and a per-cashier breakdown that don't exist yet.

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/core/database/daos/sales_dao_accounting_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedCashier(String name) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: name, role: 'user', pinHash: 'x'),
      );

  test('getStatusCountsForDateRange counts voided and refunded separately from completed', () async {
    final cashierId = await _seedCashier('Ana');
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: cashierId, status: 'completed', createdAt: DateTime(2026, 1, 1, 10)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 50, type: 'dine_in', cashierId: cashierId, status: 'voided', createdAt: DateTime(2026, 1, 1, 11)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 75, type: 'dine_in', cashierId: cashierId, status: 'refunded', createdAt: DateTime(2026, 1, 1, 12)));

    final counts = await db.salesDao.getStatusCountsForDateRange(from, to);
    expect(counts.completed, 1);
    expect(counts.voided, 1);
    expect(counts.refunded, 1);
  });

  test('getSalesByCashier groups totals per cashier within a date range', () async {
    final anaId = await _seedCashier('Ana');
    final boyId = await _seedCashier('Boy');
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);

    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: anaId, status: 'completed', createdAt: DateTime(2026, 1, 1, 10)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 60, type: 'dine_in', cashierId: boyId, status: 'completed', createdAt: DateTime(2026, 1, 1, 11)));
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 40, type: 'dine_in', cashierId: anaId, status: 'completed', createdAt: DateTime(2026, 1, 1, 12)));

    final byCashier = await db.salesDao.getSalesByCashier(from, to);
    expect(byCashier, hasLength(2));
    final ana = byCashier.firstWhere((r) => r.cashierName == 'Ana');
    expect(ana.total, 140);
    expect(ana.transactionCount, 2);
  });

  test('getRefundTotalForDateRange sums refund amounts within range', () async {
    final cashierId = await _seedCashier('Ana');
    final from = DateTime(2026, 1, 1);
    final to = DateTime(2026, 1, 2);
    final groupId = await db.into(db.productGroupsTable).insert(
        db.productGroupsTable.name.equalsExp as dynamic ?? throw UnimplementedError());
  });
}
```

**IMPORTANT for whoever implements this:** the third test above (`getRefundTotalForDateRange`) has a deliberately broken placeholder line (`db.productGroupsTable.name.equalsExp as dynamic ?? throw UnimplementedError()`) — this is intentional; the plan author did not have the exact product/product-group seeding helper memorized. **Replace that whole test body** with a proper seed using the same `_seedSaleWithOneItem`-style helper already established in `mobile/test/core/database/daos/sales_dao_test.dart` (Task 1 of Phase 1) — seed a product group, product, sale, sale item, then call `db.salesDao.recordRefund(...)` (already exists from Phase 1) for a known amount, then assert `getRefundTotalForDateRange(from, to)` returns that amount. Look at `sales_dao_test.dart`'s `_seedSaleWithOneItem` helper directly and reuse/adapt it — do not guess the schema again, it's already fully known from Phase 1.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_accounting_test.dart`
Expected: FAIL — methods don't exist yet (and you'll need to fix the placeholder test body first per the note above before this is even a meaningful compile-fail vs a real fail).

- [ ] **Step 3: Add three methods to `SalesDao`**

Add after the existing `getTopProducts` method:

```dart
  Future<StatusCounts> getStatusCountsForDateRange(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT status, COUNT(*) as cnt FROM sales WHERE created_at BETWEEN ? AND ? GROUP BY status',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {salesTable},
    ).get();
    var completed = 0, voided = 0, refunded = 0;
    for (final row in rows) {
      final status = row.read<String>('status');
      final cnt = row.read<int>('cnt');
      switch (status) {
        case 'completed':
          completed = cnt;
        case 'voided':
          voided = cnt;
        case 'refunded':
          refunded = cnt;
      }
    }
    return StatusCounts(completed: completed, voided: voided, refunded: refunded);
  }

  Future<List<CashierSales>> getSalesByCashier(DateTime from, DateTime to) async {
    final rows = await customSelect(
      'SELECT u.name as cashier_name, COALESCE(SUM(s.total), 0) as total, COUNT(*) as cnt '
      'FROM sales s JOIN users u ON u.id = s.cashier_id '
      'WHERE s.created_at BETWEEN ? AND ? AND s.status = ? '
      'GROUP BY u.id, u.name',
      variables: [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        Variable.withString('completed'),
      ],
      readsFrom: {salesTable, usersTable},
    ).get();
    return rows.map((r) => CashierSales(
          cashierName: r.read<String>('cashier_name'),
          total: r.read<double>('total'),
          transactionCount: r.read<int>('cnt'),
        )).toList();
  }

  Future<double> getRefundTotalForDateRange(DateTime from, DateTime to) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(r.total), 0) as sum FROM refunds r '
      'JOIN sales s ON s.id = r.sale_id '
      'WHERE r.created_at BETWEEN ? AND ?',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {refundsTable, salesTable},
    ).getSingle();
    return result.read<double>('sum');
  }
```

Add these two small plain classes near the top of the file (after imports, before the `@DriftAccessor` annotation) — they're simple result DTOs, not Drift tables:

```dart
class StatusCounts {
  final int completed;
  final int voided;
  final int refunded;
  const StatusCounts({required this.completed, required this.voided, required this.refunded});
}

class CashierSales {
  final String cashierName;
  final double total;
  final int transactionCount;
  const CashierSales({required this.cashierName, required this.total, required this.transactionCount});
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/core/database/daos/sales_dao_accounting_test.dart`
Expected: PASS (all 3 tests)

---

## Task 3: `CashierAccountingDao` — close/read/history logic for all three report types

**Files:**
- Create: `mobile/lib/core/database/daos/cashier_accounting_dao.dart`
- Modify: `mobile/lib/core/database/app_database.dart` (register new DAO)
- Test: `mobile/test/core/database/daos/cashier_accounting_dao_test.dart`

This DAO owns: computing a live (unclosed) snapshot for each report type, closing it (writing the persisted row), and reading history.

- [ ] **Step 1: Write the failing tests**

```dart
// mobile/test/core/database/daos/cashier_accounting_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/sales_table.dart';
import 'package:mobile/core/database/tables/users_table.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> _seedUser(String name, {String role = 'user'}) => db.into(db.usersTable).insert(
        UsersTableCompanion.insert(name: name, role: role, pinHash: 'x'),
      );

  test('getXReadingPeriodStart returns epoch when cashier has no prior close', () async {
    final cashierId = await _seedUser('Ana');
    final start = await db.cashierAccountingDao.getXReadingPeriodStart(cashierId);
    expect(start, DateTime.utc(1970));
  });

  test('closeXReading persists a row and next period starts after it', () async {
    final cashierId = await _seedUser('Ana');
    await db.salesDao.insertSale(SalesTableCompanion.insert(
        total: 100, type: 'dine_in', cashierId: cashierId, status: 'completed', createdAt: DateTime(2026, 1, 1, 10)));

    final periodEnd = DateTime(2026, 1, 1, 23, 59);
    await db.cashierAccountingDao.closeXReading(
      cashierId: cashierId,
      cashierName: 'Ana',
      periodStart: DateTime.utc(1970),
      periodEnd: periodEnd,
      totalSales: 100,
      transactionCount: 1,
      voidedCount: 0,
      refundedCount: 0,
      paymentBreakdownJson: '[]',
      topProductsJson: '[]',
    );

    final nextStart = await db.cashierAccountingDao.getXReadingPeriodStart(cashierId);
    expect(nextStart, periodEnd);

    final history = await db.cashierAccountingDao.getXReadingHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.totalSales, 100);
  });

  test('getZReadingPeriodStart and closeZReading increment zCounter', () async {
    final adminId = await _seedUser('Admin', role: 'admin');
    final cashierId = await _seedUser('Ana');

    final firstStart = await db.cashierAccountingDao.getZReadingPeriodStart();
    expect(firstStart, DateTime.utc(1970));

    await db.cashierAccountingDao.closeZReading(
      zCounter: 1,
      periodStart: firstStart,
      periodEnd: DateTime(2026, 1, 1, 23, 59),
      closedByUserId: cashierId,
      closedByName: 'Ana',
      authorizedByUserId: adminId,
      authorizedByName: 'Admin',
      beginningBalance: 500,
      endingBalance: 1500,
      totalSales: 1000,
      vatableSales: 892.86,
      vatAmount: 107.14,
      vatExemptSales: 0,
      transactionCount: 5,
      completedCount: 4,
      voidedCount: 1,
      refundedCount: 0,
      discountTotal: 0,
      cashCollected: 1000,
      totalQtySold: 10,
      paymentBreakdownJson: '[]',
      salesByCashierJson: '[]',
    );

    final nextZCounter = await db.cashierAccountingDao.getNextZCounter();
    expect(nextZCounter, 2);

    final history = await db.cashierAccountingDao.getZReadingHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.zCounter, 1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/core/database/daos/cashier_accounting_dao_test.dart`
Expected: FAIL — `cashierAccountingDao` getter doesn't exist on `AppDatabase`.

- [ ] **Step 3: Write `CashierAccountingDao`**

```dart
// mobile/lib/core/database/daos/cashier_accounting_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/x_readings_table.dart';
import '../tables/daily_reports_table.dart';
import '../tables/z_readings_table.dart';

part 'cashier_accounting_dao.g.dart';

@DriftAccessor(tables: [XReadingsTable, DailyReportsTable, ZReadingsTable])
class CashierAccountingDao extends DatabaseAccessor<AppDatabase> with _$CashierAccountingDaoMixin {
  CashierAccountingDao(super.db);

  static final _epoch = DateTime.utc(1970);

  Future<DateTime> getXReadingPeriodStart(int cashierId) async {
    final last = await (select(xReadingsTable)
          ..where((t) => t.cashierId.equals(cashierId))
          ..orderBy([(t) => OrderingTerm.desc(t.periodEnd)])
          ..limit(1))
        .getSingleOrNull();
    return last?.periodEnd ?? _epoch;
  }

  Future<int> closeXReading({
    required int cashierId,
    required String cashierName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalSales,
    required int transactionCount,
    required int voidedCount,
    required int refundedCount,
    required String paymentBreakdownJson,
    required String topProductsJson,
  }) =>
      into(xReadingsTable).insert(XReadingsTableCompanion.insert(
        cashierId: cashierId,
        cashierName: cashierName,
        periodStart: periodStart,
        periodEnd: periodEnd,
        generatedAt: DateTime.now(),
        totalSales: totalSales,
        transactionCount: transactionCount,
        voidedCount: voidedCount,
        refundedCount: refundedCount,
        paymentBreakdownJson: paymentBreakdownJson,
        topProductsJson: topProductsJson,
      ));

  Future<List<XReadingsTableData>> getXReadingHistory({required int limit, required int offset}) =>
      (select(xReadingsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<XReadingsTableData?> getXReadingById(int id) =>
      (select(xReadingsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DateTime> getDailyReportPeriodStart(int cashierId) async {
    final last = await (select(dailyReportsTable)
          ..where((t) => t.cashierId.equals(cashierId))
          ..orderBy([(t) => OrderingTerm.desc(t.periodEnd)])
          ..limit(1))
        .getSingleOrNull();
    return last?.periodEnd ?? _epoch;
  }

  Future<int> closeDailyReport({
    required int cashierId,
    required String cashierName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double grossSales,
    required double vatableSales,
    required double vatAmount,
    required double vatExemptSales,
    required double netOfTax,
    required int transactionCount,
    required int totalQtySold,
    required double cashSalesTotal,
    required int cashSalesCount,
    required String salesByProductJson,
    required String cashLedgerJson,
  }) =>
      into(dailyReportsTable).insert(DailyReportsTableCompanion.insert(
        cashierId: cashierId,
        cashierName: cashierName,
        periodStart: periodStart,
        periodEnd: periodEnd,
        generatedAt: DateTime.now(),
        grossSales: grossSales,
        vatableSales: vatableSales,
        vatAmount: vatAmount,
        vatExemptSales: vatExemptSales,
        netOfTax: netOfTax,
        transactionCount: transactionCount,
        totalQtySold: totalQtySold,
        cashSalesTotal: cashSalesTotal,
        cashSalesCount: cashSalesCount,
        salesByProductJson: salesByProductJson,
        cashLedgerJson: cashLedgerJson,
      ));

  Future<List<DailyReportsTableData>> getDailyReportHistory({required int limit, required int offset}) =>
      (select(dailyReportsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<DailyReportsTableData?> getDailyReportById(int id) =>
      (select(dailyReportsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DateTime> getZReadingPeriodStart() async {
    final last = await (select(zReadingsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.periodEnd)])
          ..limit(1))
        .getSingleOrNull();
    return last?.periodEnd ?? _epoch;
  }

  Future<int> getNextZCounter() async {
    final last = await (select(zReadingsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.zCounter)])
          ..limit(1))
        .getSingleOrNull();
    return (last?.zCounter ?? 0) + 1;
  }

  Future<int> closeZReading({
    required int zCounter,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int closedByUserId,
    required String closedByName,
    required int authorizedByUserId,
    required String authorizedByName,
    required double beginningBalance,
    required double endingBalance,
    required double totalSales,
    required double vatableSales,
    required double vatAmount,
    required double vatExemptSales,
    required int transactionCount,
    required int completedCount,
    required int voidedCount,
    required int refundedCount,
    required double discountTotal,
    required double cashCollected,
    required int totalQtySold,
    required String paymentBreakdownJson,
    required String salesByCashierJson,
  }) =>
      into(zReadingsTable).insert(ZReadingsTableCompanion.insert(
        zCounter: zCounter,
        periodStart: periodStart,
        periodEnd: periodEnd,
        generatedAt: DateTime.now(),
        closedByUserId: closedByUserId,
        closedByName: closedByName,
        authorizedByUserId: authorizedByUserId,
        authorizedByName: authorizedByName,
        beginningBalance: beginningBalance,
        endingBalance: endingBalance,
        totalSales: totalSales,
        vatableSales: vatableSales,
        vatAmount: vatAmount,
        vatExemptSales: vatExemptSales,
        transactionCount: transactionCount,
        completedCount: completedCount,
        voidedCount: voidedCount,
        refundedCount: refundedCount,
        discountTotal: discountTotal,
        cashCollected: cashCollected,
        totalQtySold: totalQtySold,
        paymentBreakdownJson: paymentBreakdownJson,
        salesByCashierJson: salesByCashierJson,
      ));

  Future<List<ZReadingsTableData>> getZReadingHistory({required int limit, required int offset}) =>
      (select(zReadingsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<ZReadingsTableData?> getZReadingById(int id) =>
      (select(zReadingsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
}
```

Register in `app_database.dart`: add `CashierAccountingDao` to the `daos:` list in `@DriftDatabase(...)`.

- [ ] **Step 4: Regenerate Drift code**

```bash
cd mobile
fvm dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd mobile && flutter test test/core/database/daos/cashier_accounting_dao_test.dart`
Expected: PASS (all 3 tests)

---

## Task 4: X-Reading feature (entity, notifier, screen, print, routing)

**Files:**
- Create: `mobile/lib/features/cashier_accounting/x_reading/entities/x_reading_data.dart`
- Create: `mobile/lib/features/cashier_accounting/x_reading/state/x_reading_notifier.dart`
- Create: `mobile/lib/features/cashier_accounting/x_reading/view/x_reading_screen.dart`
- Create: `mobile/lib/features/cashier_accounting/x_reading/view/x_reading_history_screen.dart`
- Modify: `mobile/lib/core/services/print_service.dart` (add `printXReading`)
- Modify: `mobile/lib/core/navigation/router.dart`
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart`
- Test: `mobile/test/features/cashier_accounting/x_reading/state/x_reading_notifier_test.dart`

`XReadingData` (plain class, mirrors `ReportData`'s style):
```dart
class XReadingData {
  final int? id; // null = live/unclosed preview, set once closed
  final String cashierName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;
  final double totalSales;
  final int transactionCount;
  final int voidedCount;
  final int refundedCount;
  final List<PaymentBreakdown> paymentBreakdown; // reuse existing PaymentBreakdown from reports/entities/report_data.dart
  final List<TopProductData> topProducts; // reuse existing TopProductData

  const XReadingData({
    required this.id,
    required this.cashierName,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
    required this.totalSales,
    required this.transactionCount,
    required this.voidedCount,
    required this.refundedCount,
    required this.paymentBreakdown,
    required this.topProducts,
  });
}
```

`XReadingNotifier` (`AsyncNotifier<XReadingData>`):
- `build()` computes the LIVE (unclosed) snapshot for the current logged-in cashier: `periodStart = await db.cashierAccountingDao.getXReadingPeriodStart(currentUserId)`, `periodEnd = DateTime.now()`, then calls `db.salesDao.getTotalSalesForDateRange`, `getTransactionCountForDateRange`, `getStatusCountsForDateRange`, `getPaymentBreakdown`, `getTopProducts` all with `(periodStart, periodEnd)`, assembling an `XReadingData(id: null, ...)`.
- `refresh()` re-runs `build()`'s logic (same `AsyncValue.guard` pattern as `ReportsNotifier`).
- `Future<void> close()`: takes the current live `state.value` (must be non-null, `id == null`), serializes `paymentBreakdown`/`topProducts` to JSON (use `dart:convert`'s `jsonEncode` on `.toJson()`-shaped maps — since these are plain classes without codegen, add a small manual `Map<String, Object?> toJson()` to `PaymentBreakdown`/`TopProductData` if they don't already have one, or just build the JSON-able maps inline in the notifier without touching those shared classes if adding `toJson` to them risks breaking the existing Reports feature — inline map-building is the SAFER choice, don't modify shared entities), calls `db.cashierAccountingDao.closeXReading(...)`, then reloads `build()` so the live view now reflects a fresh empty period.
- Provider: `final xReadingProvider = AsyncNotifierProvider<XReadingNotifier, XReadingData>(XReadingNotifier.new);`
- A second, separate simple `FutureProvider.family<XReadingsTableData?, int>` for reading one history row by id (for the reprint screen), and a `FutureProvider<List<XReadingsTableData>>` (or paginated notifier, mirroring `TransactionsNotifier`'s pagination pattern from Phase 1 if history could grow large) for the history list.

`XReadingScreen`: `HookConsumerWidget`, no `historyId` — always shows the LIVE unclosed snapshot via `xReadingProvider`, with a "Close & Print X-Reading" button that calls `.close()` then `PrintService.printXReading(...)`, then shows a success snackbar. Layout mirrors kiosk's sections (header, period, sales summary/payment breakdown, top products, transaction summary with voided/refunded counts) using `AppColors`/`AppSpacing`/`AppTextStyles`.

`XReadingHistoryScreen`: list of past closes (reuses the `ListView.separated` + tile pattern from `TransactionsScreen`), tapping a row navigates to a reprint view (can reuse `XReadingScreen` with an added optional `historyId` param that switches its data source to the by-id `FutureProvider`, OR a separate lightweight reprint widget — implementer's choice, but do NOT duplicate the whole rendering section widget tree; extract a shared `_XReadingReportBody` widget used by both live and history views).

`PrintService.printXReading(XReadingData data)`: new static method following the exact connect/build-bytes/write/disconnect skeleton of the existing `printReceipt` method — add section-header/amount-row helper functions at the bottom of `print_service.dart` (private, e.g. `_sectionHeader(Generator g, String title)`, `_amountRow(Generator g, String label, double amount)`) if they don't already exist, and reuse them for the other two report types in later tasks too.

Router: add `/cashier-accounting/x-reading` (live) and `/cashier-accounting/x-reading/history` (+ `/:id` for reprint) routes.

Dashboard: this task adds ONE new tile, `_kTileCashierAccounting` (label "Cashier Accounting", pick an unused accent color, route `/cashier-accounting`) which — since there's no single "cashier accounting home" screen yet — for THIS task alone, route it directly to `/cashier-accounting/x-reading` (Task 5 and Task 6 will need to either add a small tab/menu screen at `/cashier-accounting` that links to all three, or the last task in this phase should introduce that hub screen — flag this explicitly in Task 6 below).

- [ ] **Step 1: Write the failing notifier test** (seed a cashier + a completed sale, assert `xReadingProvider` returns the right `totalSales`/`transactionCount`; a second test calls `.close()` and asserts a subsequent `build()` shows `totalSales: 0` for the new empty period, and that `db.cashierAccountingDao.getXReadingHistory(...)` now has one row)
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `XReadingData`, `XReadingNotifier`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Build `XReadingScreen` + `XReadingHistoryScreen`**
- [ ] **Step 6: Add `PrintService.printXReading` + shared byte-building helpers**
- [ ] **Step 7: Wire router + dashboard tile**
- [ ] **Step 8: `dart analyze`, confirm only expected dangling references (if `/cashier-accounting` hub screen doesn't exist yet, tile route should point directly at `/cashier-accounting/x-reading` for now, not dangle)**

*(Full step-by-step code for the screen/print-service bodies is intentionally left to the implementer to write following the patterns described above and the exact section list from the kiosk research — this task's prose specification is complete enough to implement without guessing data shapes; implementer should ask if genuinely blocked rather than invent new DAO methods.)*

---

## Task 5: Daily Report feature (entity, notifier, screen, print, routing)

**Files:**
- Create: `mobile/lib/features/cashier_accounting/daily_report/entities/daily_report_data.dart`
- Create: `mobile/lib/features/cashier_accounting/daily_report/state/daily_report_notifier.dart`
- Create: `mobile/lib/features/cashier_accounting/daily_report/view/daily_report_screen.dart`
- Create: `mobile/lib/features/cashier_accounting/daily_report/view/daily_report_history_screen.dart`
- Modify: `mobile/lib/core/services/print_service.dart` (add `printDailyReport`, reusing Task 4's shared helpers)
- Modify: `mobile/lib/core/navigation/router.dart`
- Test: `mobile/test/features/cashier_accounting/daily_report/state/daily_report_notifier_test.dart`

Same structure as Task 4, but:
- VAT split: `vatableSales = grossSales / (1 + taxRate)`, `vatAmount = grossSales - vatableSales`, `vatExemptSales = 0` (mobile has no exemption flag on any sale — always 0 unless/until a future phase adds one; read `store_info.taxRate` via `db.storeInfoDao` — confirm exact method name by reading `store_info_dao.dart` before use, do not guess).
- `netOfTax = grossSales - vatAmount`.
- "Cash sales" = sum/count of sales whose payments include a `method == 'cash'` payment row (join `payments` same way `getPaymentBreakdown` already does — add a new `SalesDao.getCashSalesForDateRange(from, to)` returning `(double total, int count)` if no suitable existing method covers it).
- `salesByProduct` reuses `SalesDao.getTopProducts` (no separate limit — pass a high limit like 1000 to effectively get "all", or add an optional `limit` already-nullable parameter check — `getTopProducts` currently defaults `limit = 5`; either call it with `limit: 1000` or confirm whether an unlimited variant is warranted — prefer just passing a large limit over adding a new DAO method, YAGNI).
- `cashLedger` groups completed sales by calendar day within the period — implement via a new `SalesDao.getCashLedger(from, to)` returning `List<{date: DateTime, total: double}>` (GROUP BY `date(created_at)`).
- Close requires no supervisor authorization (matches kiosk — unlike Z-Reading).

- [ ] **Step 1: Write the failing notifier test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `DailyReportData`, `DailyReportNotifier`, any new `SalesDao` methods needed (`getCashSalesForDateRange`, `getCashLedger`)**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Build `DailyReportScreen` + `DailyReportHistoryScreen`**
- [ ] **Step 6: Add `PrintService.printDailyReport`**
- [ ] **Step 7: Wire router (`/cashier-accounting/daily-report` + history/:id)**
- [ ] **Step 8: `dart analyze` clean**

---

## Task 6: Z-Reading feature (entity, notifier, screen with supervisor auth, print, routing) + Cashier Accounting hub screen

**Files:**
- Create: `mobile/lib/features/cashier_accounting/z_reading/entities/z_reading_data.dart`
- Create: `mobile/lib/features/cashier_accounting/z_reading/state/z_reading_notifier.dart`
- Create: `mobile/lib/features/cashier_accounting/z_reading/view/z_reading_screen.dart`
- Create: `mobile/lib/features/cashier_accounting/z_reading/view/z_reading_history_screen.dart`
- Create: `mobile/lib/features/cashier_accounting/view/cashier_accounting_hub_screen.dart` (**new** — the tab/menu hub linking to X-Reading, Daily Report, Z-Reading, replacing the temporary direct-to-X-Reading dashboard route from Task 4)
- Modify: `mobile/lib/core/services/print_service.dart` (add `printZReading`)
- Modify: `mobile/lib/core/navigation/router.dart`
- Modify: `mobile/lib/features/dashboard/view/dashboard_screen.dart` (point `_kTileCashierAccounting.route` at `/cashier-accounting` — the new hub — instead of Task 4's temporary direct link)
- Test: `mobile/test/features/cashier_accounting/z_reading/state/z_reading_notifier_test.dart`

Z-Reading differs from X-Reading/Daily Report:
- **Store-wide**, not per-cashier: period start/end come from `getZReadingPeriodStart()`/`getNextZCounter()` (no `cashierId` filter on any of the underlying `SalesDao` queries — pass the full store's date range).
- **Requires supervisor/admin PIN authorization to close** — reuse `RefundAuthDialog`'s pattern from Phase 1 (built at `mobile/lib/features/transactions/view/refund_auth_dialog.dart`, calling `authNotifierProvider.notifier.verifySupervisorPin(pin)`). Either reuse that exact widget directly (it's not transaction-specific in its implementation, just named for that context — importing it cross-feature is acceptable, OR duplicate a nearly-identical dialog under `cashier_accounting` if the implementer judges that a cross-feature import from `transactions/` into `cashier_accounting/` is architecturally awkward; prefer reuse over duplication unless it creates a real circular-dependency problem).
- Requires manual **beginning/ending cash balance** input — two `TextField`s (numeric) on the close confirmation flow, captured before the auth dialog or as part of it — implementer's choice on exact UX flow, but both values must be present before `closeZReading(...)` is called.
- Includes `salesByCashier` breakdown via the new `SalesDao.getSalesByCashier` (Task 2).
- `closedByUserId`/`closedByName` = whoever is currently logged in (the person tapping "Close"); `authorizedByUserId`/`authorizedByName` = whichever admin's PIN was verified (note: `verifySupervisorPin` currently only returns `bool`, not which admin matched — if the UI needs to record which specific admin authorized, this requires reading `mobile/lib/features/auth/repositories/auth_repository_impl.dart:verifyAdminPin` and extending it to return the matched admin's `UserEntity` instead of/in addition to `bool`, OR — simpler, avoiding touching Phase-1's already-reviewed auth code — just record `authorizedByName: 'Supervisor'` as a generic label since mobile doesn't track which specific admin approved, only that one did. **Recommend the simpler option** to avoid re-opening Phase-1 code; note this as a documented simplification, not a silent gap).

**Cashier Accounting hub screen** (`CashierAccountingHubScreen`): a simple `Scaffold` with three large tappable cards/tiles — "X-Reading", "Daily Report", "Z-Reading" — each navigating to its respective route. Mirrors the visual weight of `DashboardScreen`'s tile grid but scoped to just these three (plus maybe a 4th "History" entry point per type, or fold history access into each report screen's app bar as an icon button — implementer's choice, keep it simple).

- [ ] **Step 1: Write the failing notifier test** (seed an admin + a cashier + sales, verify `zReadingProvider` computes store-wide totals across BOTH cashiers; verify `close()` requires the caller to have already authorized — i.e. `close()` itself doesn't re-check PIN, the UI layer does, matching how `RefundScreen`'s `_submitRefund` gates on `RefundAuthDialog` before calling the DAO — the notifier's `close()` method just needs `authorizedByUserId`/`authorizedByName` passed in as parameters, already-verified by the caller)
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `ZReadingData`, `ZReadingNotifier`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Build `ZReadingScreen` (with auth-gated close + cash balance inputs) + `ZReadingHistoryScreen`**
- [ ] **Step 6: Add `PrintService.printZReading`**
- [ ] **Step 7: Build `CashierAccountingHubScreen`, wire full router tree (`/cashier-accounting`, `/cashier-accounting/x-reading(+/history/:id)`, `/cashier-accounting/daily-report(+/history/:id)`, `/cashier-accounting/z-reading(+/history/:id)`)**
- [ ] **Step 8: Update dashboard tile to point at `/cashier-accounting` hub**
- [ ] **Step 9: `dart analyze` clean across the whole `cashier_accounting` feature + router + dashboard**

---

## Task 7: Manual verification pass for Phase 2

- [ ] **Step 1: Run full mobile test suite** — `cd mobile && fvm flutter test` — all pass, including new schema/DAO/notifier tests.
- [ ] **Step 2: Run the app and walk the golden path:**
  1. Complete 2-3 sales as a non-admin cashier, one voided.
  2. Dashboard → Cashier Accounting → X-Reading — shows correct live totals/counts for the current cashier only.
  3. Close X-Reading, confirm print is attempted (or fails gracefully if no printer paired — check `PrintService`'s existing error handling pattern), confirm history shows the closed entry, confirm a fresh X-Reading now shows zero/empty.
  4. Same walkthrough for Daily Report (no auth required to close).
  5. Log in as a second cashier, make a sale, then check Z-Reading shows BOTH cashiers' totals combined (store-wide).
  6. Close Z-Reading as an admin (PIN prompt required), enter beginning/ending cash balance, confirm it closes, prints, appears in history with an incrementing Z-counter, and a fresh Z-Reading afterward starts from zero.

If any step fails, use `superpowers:systematic-debugging` before patching — do not guess-fix.

---

## Self-Review Notes

- **Spec coverage:** All of Phase 2's scoped bullet points from the parent plan (new DAO aggregation queries, a "close shift" concept via new tables + migration, report-preview UI, ESC/POS print reuse) are covered by Tasks 1-6. The parent plan's open question — "whether Z-Reading on mobile should hard-close/lock past sales" — is answered by the design decision: yes, closes persist and scope the next period, matching kiosk.
- **No blind trust in memory-only claims:** Task 5 explicitly instructs the implementer to read `store_info_dao.dart` for the real tax-rate accessor name rather than guessing; Task 6 explicitly flags the `authorizedByName` simplification as a documented tradeoff, not a silent gap.
- **Type consistency:** `XReadingData`/`DailyReportData`/`ZReadingData`, their notifiers, and the DAO methods that feed them use consistent field names throughout (`totalSales`, `transactionCount`, `voidedCount`, `refundedCount`, `paymentBreakdownJson`, etc.) matching the Drift table column names 1:1 to avoid mapping bugs.
- **Known scope simplification (intentional, not an oversight):** cash beginning/ending balance is a manual number entry, VAT is an approximation from a single global tax rate, and Z-Reading's "authorized by" is either a real admin identity or a generic label depending on implementer's Task 6 choice — all three were explicit tradeoffs confirmed with the user before writing this plan, not gaps introduced silently.
