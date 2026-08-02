import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../reports/entities/report_data.dart';
import '../entities/x_reading_data.dart';

class XReadingNotifier extends AsyncNotifier<XReadingData> {
  @override
  Future<XReadingData> build() => _load();

  int get _currentUserId {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      throw StateError('X-Reading requires a logged-in cashier');
    }
    return authState.user.id;
  }

  String get _currentUserName {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      throw StateError('X-Reading requires a logged-in cashier');
    }
    return authState.user.name;
  }

  Future<XReadingData> _load() async {
    final db = ref.watch(databaseProvider);
    final cashierId = _currentUserId;
    final cashierName = _currentUserName;

    final periodStart = await db.cashierAccountingDao.getXReadingPeriodStart(cashierId);
    final periodEnd = DateTime.now();

    final totalSales = await db.salesDao.getTotalSalesForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final transactionCount =
        await db.salesDao.getTransactionCountForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final statusCounts = await db.salesDao.getStatusCountsForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final paymentRows = await db.salesDao.getPaymentBreakdownForCashier(periodStart, periodEnd, cashierId);
    final topProductRows = await db.salesDao.getTopProductsForCashier(periodStart, periodEnd, cashierId, limit: 5);
    final discounts = await db.salesDao.getDiscountBreakdownForCashier(periodStart, periodEnd, cashierId);
    final vatBreakdown = await db.salesDao.getVatBreakdownForCashier(periodStart, periodEnd, cashierId);
    final saleStats = await db.salesDao.getSaleStatsForCashier(periodStart, periodEnd, cashierId);
    final cashSales = await db.salesDao.getCashSalesForDateRangeAndCashier(periodStart, periodEnd, cashierId);
    final paymentLedgers = await db.salesDao.getPaymentLedgerForCashier(periodStart, periodEnd, cashierId);

    final totalPaid = paymentRows.fold(0.0, (s, r) => s + (r['total'] as double? ?? 0));
    final paymentBreakdown = paymentRows.map((r) {
      final amt = r['total'] as double? ?? 0;
      return PaymentBreakdown(
        method: r['method'] as String,
        total: amt,
        percentage: totalPaid > 0 ? (amt / totalPaid * 100) : 0,
      );
    }).toList();

    final topProducts = topProductRows.map((r) => TopProductData(
          name: r['name'] as String,
          quantity: r['qty'] as int? ?? 0,
          total: r['amount'] as double? ?? 0,
        )).toList();

    return XReadingData(
      id: null,
      cashierName: cashierName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      generatedAt: DateTime.now(),
      totalSales: totalSales,
      transactionCount: transactionCount,
      voidedCount: statusCounts.voided,
      refundedCount: statusCounts.refunded,
      paymentBreakdown: paymentBreakdown,
      topProducts: topProducts,
      paymentLedgers: paymentLedgers,
      discounts: discounts,
      totalDiscounts: discounts.fold(0.0, (s, d) => s + d.amount),
      vatableSales: vatBreakdown.vatableSales,
      vatAmount: vatBreakdown.vatAmount,
      vatExemptSales: vatBreakdown.vatExemptSales,
      averageSale: saleStats.average,
      highestSale: saleStats.highest,
      lowestSale: saleStats.lowest,
      cashCollected: cashSales.total,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> close() async {
    final data = state.value;
    if (data == null) {
      throw StateError('Cannot close X-Reading before it has loaded');
    }
    if (data.id != null) {
      throw StateError('Cannot close an already-closed X-Reading');
    }

    final db = ref.read(databaseProvider);
    final cashierId = _currentUserId;

    final paymentBreakdownJson = jsonEncode(data.paymentBreakdown
        .map((p) => {'method': p.method, 'total': p.total, 'percentage': p.percentage})
        .toList());
    final topProductsJson = jsonEncode(data.topProducts
        .map((p) => {'name': p.name, 'quantity': p.quantity, 'total': p.total})
        .toList());
    final discountsJson =
        jsonEncode(data.discounts.map((d) => {'name': d.name, 'amount': d.amount}).toList());
    final paymentLedgersJson = PaymentLedger.encodeList(data.paymentLedgers);

    await db.cashierAccountingDao.closeXReading(
      cashierId: cashierId,
      cashierName: data.cashierName,
      periodStart: data.periodStart,
      periodEnd: data.periodEnd,
      totalSales: data.totalSales,
      transactionCount: data.transactionCount,
      voidedCount: data.voidedCount,
      refundedCount: data.refundedCount,
      paymentBreakdownJson: paymentBreakdownJson,
      topProductsJson: topProductsJson,
      discountsJson: discountsJson,
      totalDiscounts: data.totalDiscounts,
      vatableSales: data.vatableSales,
      vatAmount: data.vatAmount,
      vatExemptSales: data.vatExemptSales,
      averageSale: data.averageSale,
      highestSale: data.highestSale,
      lowestSale: data.lowestSale,
      cashCollected: data.cashCollected,
      paymentLedgersJson: paymentLedgersJson,
    );

    ref.invalidate(xReadingHistoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final xReadingProvider =
    AsyncNotifierProvider<XReadingNotifier, XReadingData>(XReadingNotifier.new);

final xReadingHistoryRowProvider =
    FutureProvider.family<XReadingsTableData?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getXReadingById(id);
});

final xReadingHistoryProvider = FutureProvider<List<XReadingsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getXReadingHistory(limit: 50, offset: 0);
});
