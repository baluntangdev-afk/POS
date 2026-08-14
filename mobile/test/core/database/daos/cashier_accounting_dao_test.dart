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
      discountsJson: '[]',
      totalDiscounts: 0,
      vatableSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      averageSale: 0,
      highestSale: 0,
      lowestSale: 0,
      cashCollected: 0,
      paymentLedgersJson: '[]',
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
      discountsJson: '[]',
      paymentLedgersJson: '[]',
    );

    final nextZCounter = await db.cashierAccountingDao.getNextZCounter();
    expect(nextZCounter, 2);

    final history = await db.cashierAccountingDao.getZReadingHistory(limit: 10, offset: 0);
    expect(history, hasLength(1));
    expect(history.first.zCounter, 1);
  });

  test('getVoidLockCutoff returns epoch when the cashier has no closed reports', () async {
    final cashierId = await _seedUser('Ana');
    final cutoff = await db.cashierAccountingDao.getVoidLockCutoff(cashierId);
    expect(cutoff, DateTime.utc(1970));
  });

  test('getVoidLockCutoff returns the latest of X-Reading, Daily Report and Z-Reading', () async {
    final adminId = await _seedUser('Admin', role: 'admin');
    final cashierId = await _seedUser('Ana');

    await db.cashierAccountingDao.closeXReading(
      cashierId: cashierId,
      cashierName: 'Ana',
      periodStart: DateTime.utc(1970),
      periodEnd: DateTime(2026, 1, 1, 12),
      totalSales: 100,
      transactionCount: 1,
      voidedCount: 0,
      refundedCount: 0,
      paymentBreakdownJson: '[]',
      topProductsJson: '[]',
      discountsJson: '[]',
      totalDiscounts: 0,
      vatableSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      averageSale: 0,
      highestSale: 0,
      lowestSale: 0,
      cashCollected: 0,
      paymentLedgersJson: '[]',
    );

    await db.cashierAccountingDao.closeDailyReport(
      cashierId: cashierId,
      cashierName: 'Ana',
      periodStart: DateTime.utc(1970),
      periodEnd: DateTime(2026, 1, 1, 18),
      grossSales: 100,
      vatableSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      netOfTax: 100,
      transactionCount: 1,
      totalQtySold: 1,
      cashSalesTotal: 100,
      cashSalesCount: 1,
      salesByProductJson: '[]',
      cashLedgerJson: '[]',
    );

    // Daily Report (18:00) is the latest so far.
    expect(await db.cashierAccountingDao.getVoidLockCutoff(cashierId), DateTime(2026, 1, 1, 18));

    await db.cashierAccountingDao.closeZReading(
      zCounter: 1,
      periodStart: DateTime.utc(1970),
      periodEnd: DateTime(2026, 1, 1, 23, 59),
      closedByUserId: cashierId,
      closedByName: 'Ana',
      authorizedByUserId: adminId,
      authorizedByName: 'Admin',
      beginningBalance: 0,
      endingBalance: 100,
      totalSales: 100,
      vatableSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      transactionCount: 1,
      completedCount: 1,
      voidedCount: 0,
      refundedCount: 0,
      discountTotal: 0,
      cashCollected: 100,
      totalQtySold: 1,
      paymentBreakdownJson: '[]',
      salesByCashierJson: '[]',
      discountsJson: '[]',
      paymentLedgersJson: '[]',
    );

    // Z-Reading (23:59) is now the latest.
    expect(
      await db.cashierAccountingDao.getVoidLockCutoff(cashierId),
      DateTime(2026, 1, 1, 23, 59),
    );
  });

  test('getVoidLockCutoff treats Z-Reading as store-wide across cashiers', () async {
    final adminId = await _seedUser('Admin', role: 'admin');
    final cashierA = await _seedUser('Ana');
    final cashierB = await _seedUser('Ben');

    await db.cashierAccountingDao.closeZReading(
      zCounter: 1,
      periodStart: DateTime.utc(1970),
      periodEnd: DateTime(2026, 1, 1, 23, 59),
      closedByUserId: cashierA,
      closedByName: 'Ana',
      authorizedByUserId: adminId,
      authorizedByName: 'Admin',
      beginningBalance: 0,
      endingBalance: 100,
      totalSales: 100,
      vatableSales: 0,
      vatAmount: 0,
      vatExemptSales: 0,
      transactionCount: 1,
      completedCount: 1,
      voidedCount: 0,
      refundedCount: 0,
      discountTotal: 0,
      cashCollected: 100,
      totalQtySold: 1,
      paymentBreakdownJson: '[]',
      salesByCashierJson: '[]',
      discountsJson: '[]',
      paymentLedgersJson: '[]',
    );

    // Ben never closed his own X-Reading/Daily Report, but the store-wide Z-Reading still applies.
    expect(
      await db.cashierAccountingDao.getVoidLockCutoff(cashierB),
      DateTime(2026, 1, 1, 23, 59),
    );
  });
}
