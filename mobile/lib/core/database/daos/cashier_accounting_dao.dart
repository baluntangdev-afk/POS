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
