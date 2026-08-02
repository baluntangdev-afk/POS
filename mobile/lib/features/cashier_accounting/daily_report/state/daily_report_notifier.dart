import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../reports/entities/report_data.dart';
import '../entities/daily_report_data.dart';

class DailyReportNotifier extends AsyncNotifier<DailyReportData> {
  @override
  Future<DailyReportData> build() => _load();

  int get _currentUserId {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      throw StateError('Daily Report requires a logged-in cashier');
    }
    return authState.user.id;
  }

  String get _currentUserName {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      throw StateError('Daily Report requires a logged-in cashier');
    }
    return authState.user.name;
  }

  Future<DailyReportData> _load() async {
    final db = ref.watch(databaseProvider);
    final cashierId = _currentUserId;
    final cashierName = _currentUserName;

    final periodStart = await db.cashierAccountingDao.getDailyReportPeriodStart(cashierId);
    final periodEnd = DateTime.now();

    final grossSales = await db.salesDao.getTotalSalesForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final transactionCount =
        await db.salesDao.getTransactionCountForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final totalQtySold =
        await db.salesDao.getTotalQtySoldForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final cashSales = await db.salesDao.getCashSalesForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final topProductRows =
        await db.salesDao.getTopProductsForCashier(periodStart, periodEnd, cashierId, limit: 1000);
    final ledgerRows =
        await db.salesDao.getCashLedgerEntriesForCashier(periodStart, periodEnd, cashierId);
    final vatBreakdown = await db.salesDao.getVatBreakdownForCashier(periodStart, periodEnd, cashierId);

    final storeInfo = await db.storeInfoDao.getStoreInfo();
    final taxRate = storeInfo?.taxRate ?? 0.0;
    final vatableSales = grossSales / (1 + taxRate);
    final vatAmount = grossSales - vatableSales;
    final vatExemptSales = vatBreakdown.vatExemptSales;
    final netOfTax = grossSales - vatAmount;

    final salesByProduct = topProductRows
        .map((r) => TopProductData(
              name: r['name'] as String,
              quantity: r['qty'] as int? ?? 0,
              total: r['amount'] as double? ?? 0,
            ))
        .toList();

    final cashLedger = ledgerRows
        .map((r) => CashLedgerEntry(time: r.time, reference: r.reference, amount: r.amount))
        .toList();

    return DailyReportData(
      id: null,
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
      cashSalesTotal: cashSales.total,
      cashSalesCount: cashSales.count,
      salesByProduct: salesByProduct,
      cashLedger: cashLedger,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> close() async {
    final data = state.value;
    if (data == null) {
      throw StateError('Cannot close Daily Report before it has loaded');
    }
    if (data.id != null) {
      throw StateError('Cannot close an already-closed Daily Report');
    }

    final db = ref.read(databaseProvider);
    final cashierId = _currentUserId;

    final salesByProductJson = jsonEncode(data.salesByProduct
        .map((p) => {'name': p.name, 'quantity': p.quantity, 'total': p.total})
        .toList());
    final cashLedgerJson = jsonEncode(data.cashLedger
        .map((e) => {
              'time': e.time.toIso8601String(),
              'reference': e.reference,
              'amount': e.amount,
            })
        .toList());

    await db.cashierAccountingDao.closeDailyReport(
      cashierId: cashierId,
      cashierName: data.cashierName,
      periodStart: data.periodStart,
      periodEnd: data.periodEnd,
      grossSales: data.grossSales,
      vatableSales: data.vatableSales,
      vatAmount: data.vatAmount,
      vatExemptSales: data.vatExemptSales,
      netOfTax: data.netOfTax,
      transactionCount: data.transactionCount,
      totalQtySold: data.totalQtySold,
      cashSalesTotal: data.cashSalesTotal,
      cashSalesCount: data.cashSalesCount,
      salesByProductJson: salesByProductJson,
      cashLedgerJson: cashLedgerJson,
    );

    ref.invalidate(dailyReportHistoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final dailyReportProvider =
    AsyncNotifierProvider<DailyReportNotifier, DailyReportData>(DailyReportNotifier.new);

final dailyReportHistoryRowProvider =
    FutureProvider.family<DailyReportsTableData?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getDailyReportById(id);
});

final dailyReportHistoryProvider = FutureProvider<List<DailyReportsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getDailyReportHistory(limit: 50, offset: 0);
});
