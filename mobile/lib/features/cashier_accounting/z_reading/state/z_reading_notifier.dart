import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../reports/entities/report_data.dart';
import '../entities/z_reading_data.dart';

/// Z-Reading is store-wide (NOT scoped to the current cashier). Anyone who is
/// logged in may VIEW the live period; only [close] is gated behind a
/// supervisor PIN, and that gate is enforced at the UI layer (see
/// [ZReadingScreen]) — this notifier does not re-check any PIN itself.
class ZReadingNotifier extends AsyncNotifier<ZReadingData> {
  @override
  Future<ZReadingData> build() => _load();

  String get _currentUserName {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      throw StateError('Z-Reading requires a logged-in user');
    }
    return authState.user.name;
  }

  Future<ZReadingData> _load() async {
    final db = ref.watch(databaseProvider);
    final closedByName = _currentUserName;

    // Lower bound for "unreported since" — may be a synthetic epoch/last-close
    // boundary with no transaction actually at that time, so it's only used
    // to scope the queries below, never shown directly to the user.
    final queryStart = await db.cashierAccountingDao.getZReadingPeriodStart();
    final periodEnd = DateTime.now();
    final periodStart = await db.salesDao.getEarliestTransactionDate(queryStart, periodEnd);
    final nextZCounter = await db.cashierAccountingDao.getNextZCounter();

    final totalSales = await db.salesDao.getTotalSalesForDateRange(queryStart, periodEnd);
    final transactionCount = await db.salesDao.getTransactionCountForDateRange(queryStart, periodEnd);
    final statusCounts = await db.salesDao.getStatusCountsForDateRange(queryStart, periodEnd);
    final discountTotal = await db.salesDao.getDiscountTotalForDateRange(queryStart, periodEnd);
    final totalQtySold = await db.salesDao.getTotalQtySoldForDateRange(queryStart, periodEnd);
    final cashSales = await db.salesDao.getCashSalesForDateRange(queryStart, periodEnd);
    final paymentRows = await db.salesDao.getPaymentBreakdown(queryStart, periodEnd);
    final cashierRows = await db.salesDao.getSalesByCashier(queryStart, periodEnd);
    final discounts = await db.salesDao.getDiscountBreakdownForDateRange(queryStart, periodEnd);
    final vatBreakdown = await db.salesDao.getVatBreakdownForDateRange(queryStart, periodEnd);
    final beginningBalance = await db.cashierAccountingDao.getLastZReadingEndingBalance();
    final paymentLedgers = await db.salesDao.getPaymentLedgerForDateRange(queryStart, periodEnd);

    final storeInfo = await db.storeInfoDao.getStoreInfo();
    final taxRate = storeInfo?.taxRate ?? 0.0;
    final vatableSales = totalSales / (1 + taxRate);
    final vatAmount = totalSales - vatableSales;
    final vatExemptSales = vatBreakdown.vatExemptSales;

    final totalPaid = paymentRows.fold(0.0, (s, r) => s + (r['total'] as double? ?? 0));
    final paymentBreakdown = paymentRows.map((r) {
      final amt = r['total'] as double? ?? 0;
      return PaymentBreakdown(
        method: r['method'] as String,
        total: amt,
        percentage: totalPaid > 0 ? (amt / totalPaid * 100) : 0,
      );
    }).toList();

    final salesByCashier = cashierRows
        .map((r) => CashierSalesBreakdown(
              cashierName: r.cashierName,
              total: r.total,
              transactionCount: r.transactionCount,
            ))
        .toList();

    return ZReadingData(
      id: null,
      zCounter: nextZCounter,
      periodStart: periodStart,
      periodEnd: periodEnd,
      generatedAt: DateTime.now(),
      closedByName: closedByName,
      authorizedByName: '',
      beginningBalance: beginningBalance,
      endingBalance: beginningBalance + totalSales,
      totalSales: totalSales,
      vatableSales: vatableSales,
      vatAmount: vatAmount,
      vatExemptSales: vatExemptSales,
      transactionCount: transactionCount,
      completedCount: statusCounts.completed,
      voidedCount: statusCounts.voided,
      refundedCount: statusCounts.refunded,
      discountTotal: discountTotal,
      cashCollected: cashSales.total,
      totalQtySold: totalQtySold,
      paymentBreakdown: paymentBreakdown,
      paymentLedgers: paymentLedgers,
      salesByCashier: salesByCashier,
      discounts: discounts,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Closes the current live period. The supervisor PIN must already have
  /// been verified by the caller (UI layer, via [RefundAuthDialog]) — this
  /// method performs no PIN re-check. `beginningBalance`/`endingBalance` are
  /// not passed in — they're the running cumulative totals already computed
  /// in [_load] (mirrors kiosk's backend, which derives them the same way).
  Future<void> close({
    required int closedByUserId,
    required String closedByName,
    required int authorizedByUserId,
    required String authorizedByName,
  }) async {
    final data = state.value;
    if (data == null) {
      throw StateError('Cannot close Z-Reading before it has loaded');
    }
    if (data.id != null) {
      throw StateError('Cannot close an already-closed Z-Reading');
    }
    final periodStart = data.periodStart;
    if (periodStart == null) {
      throw StateError('Cannot close Z-Reading with no transactions');
    }

    final db = ref.read(databaseProvider);
    final zCounter = await db.cashierAccountingDao.getNextZCounter();

    final paymentBreakdownJson = jsonEncode(data.paymentBreakdown
        .map((p) => {'method': p.method, 'total': p.total, 'percentage': p.percentage})
        .toList());
    final salesByCashierJson = jsonEncode(data.salesByCashier
        .map((c) => {
              'cashierName': c.cashierName,
              'total': c.total,
              'transactionCount': c.transactionCount,
            })
        .toList());
    final discountsJson =
        jsonEncode(data.discounts.map((d) => {'name': d.name, 'amount': d.amount}).toList());
    final paymentLedgersJson = PaymentLedger.encodeList(data.paymentLedgers);

    await db.cashierAccountingDao.closeZReading(
      zCounter: zCounter,
      periodStart: periodStart,
      periodEnd: data.periodEnd,
      closedByUserId: closedByUserId,
      closedByName: closedByName,
      authorizedByUserId: authorizedByUserId,
      authorizedByName: authorizedByName,
      beginningBalance: data.beginningBalance,
      endingBalance: data.endingBalance,
      totalSales: data.totalSales,
      vatableSales: data.vatableSales,
      vatAmount: data.vatAmount,
      vatExemptSales: data.vatExemptSales,
      transactionCount: data.transactionCount,
      completedCount: data.completedCount,
      voidedCount: data.voidedCount,
      refundedCount: data.refundedCount,
      discountTotal: data.discountTotal,
      cashCollected: data.cashCollected,
      totalQtySold: data.totalQtySold,
      paymentBreakdownJson: paymentBreakdownJson,
      salesByCashierJson: salesByCashierJson,
      discountsJson: discountsJson,
      paymentLedgersJson: paymentLedgersJson,
    );

    ref.invalidate(zReadingHistoryProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final zReadingProvider = AsyncNotifierProvider<ZReadingNotifier, ZReadingData>(ZReadingNotifier.new);

final zReadingHistoryRowProvider = FutureProvider.family<ZReadingsTableData?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getZReadingById(id);
});

final zReadingHistoryProvider = FutureProvider<List<ZReadingsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.cashierAccountingDao.getZReadingHistory(limit: 50, offset: 0);
});
