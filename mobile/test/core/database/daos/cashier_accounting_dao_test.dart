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
}
