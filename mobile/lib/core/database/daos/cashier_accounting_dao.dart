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
    required String discountsJson,
    required double totalDiscounts,
    required double vatableSales,
    required double vatAmount,
    required double vatExemptSales,
    required double averageSale,
    required double highestSale,
    required double lowestSale,
    required double cashCollected,
    required String paymentLedgersJson,
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
        discountsJson: Value(discountsJson),
        totalDiscounts: Value(totalDiscounts),
        vatableSales: Value(vatableSales),
        vatAmount: Value(vatAmount),
        vatExemptSales: Value(vatExemptSales),
        averageSale: Value(averageSale),
        highestSale: Value(highestSale),
        lowestSale: Value(lowestSale),
        cashCollected: Value(cashCollected),
        paymentLedgersJson: Value(paymentLedgersJson),
      ));

  Future<List<XReadingsTableData>> getXReadingHistory({
    required int limit,
    required int offset,
    int? cashierId,
  }) =>
      (select(xReadingsTable)
            ..where((t) => cashierId == null ? const Constant(true) : t.cashierId.equals(cashierId))
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

  Future<List<DailyReportsTableData>> getDailyReportHistory({
    required int limit,
    required int offset,
    int? cashierId,
  }) =>
      (select(dailyReportsTable)
            ..where((t) => cashierId == null ? const Constant(true) : t.cashierId.equals(cashierId))
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

  /// The running cumulative balance carried forward from the last closed
  /// Z-Reading (its endingBalance), or 0 if none has been closed yet. Mirrors
  /// kiosk's backend, where beginningBalance is always the prior Z-Reading's
  /// endingBalance rather than a manually-counted cash drawer amount.
  Future<double> getLastZReadingEndingBalance() async {
    final last = await (select(zReadingsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.zCounter)])
          ..limit(1))
        .getSingleOrNull();
    return last?.endingBalance ?? 0;
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
    required String discountsJson,
    required String paymentLedgersJson,
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
        discountsJson: Value(discountsJson),
        paymentLedgersJson: Value(paymentLedgersJson),
      ));

  Future<List<ZReadingsTableData>> getZReadingHistory({required int limit, required int offset}) =>
      (select(zReadingsTable)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<ZReadingsTableData?> getZReadingById(int id) =>
      (select(zReadingsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
}
