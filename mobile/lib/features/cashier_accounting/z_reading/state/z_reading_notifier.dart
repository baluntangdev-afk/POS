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

    final periodStart = await db.cashierAccountingDao.getZReadingPeriodStart();
    final periodEnd = DateTime.now();
    final nextZCounter = await db.cashierAccountingDao.getNextZCounter();

    final totalSales = await db.salesDao.getTotalSalesForDateRange(periodStart, periodEnd);
    final transactionCount = await db.salesDao.getTransactionCountForDateRange(periodStart, periodEnd);
    final statusCounts = await db.salesDao.getStatusCountsForDateRange(periodStart, periodEnd);
    final discountTotal = await db.salesDao.getDiscountTotalForDateRange(periodStart, periodEnd);
    final totalQtySold = await db.salesDao.getTotalQtySoldForDateRange(periodStart, periodEnd);
    final cashSales = await db.salesDao.getCashSalesForDateRange(periodStart, periodEnd);
    final paymentRows = await db.salesDao.getPaymentBreakdown(periodStart, periodEnd);
    final cashierRows = await db.salesDao.getSalesByCashier(periodStart, periodEnd);

    final storeInfo = await db.storeInfoDao.getStoreInfo();
    final taxRate = storeInfo?.taxRate ?? 0.0;
    final vatableSales = totalSales / (1 + taxRate);
    final vatAmount = totalSales - vatableSales;
    const vatExemptSales = 0.0;

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
      beginningBalance: 0,
      endingBalance: 0,
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
      salesByCashier: salesByCashier,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Closes the current live period. The supervisor PIN must already have
  /// been verified by the caller (UI layer, via [RefundAuthDialog]) — this
  /// method performs no PIN re-check.
  ///
  /// KNOWN SIMPLIFICATION: `AuthNotifier.verifySupervisorPin` only returns a
  /// bool, not which admin/supervisor matched the PIN. Rather than modifying
  /// Phase-1 auth code, the UI passes a generic `authorizedByName:
  /// 'Supervisor'` and `authorizedByUserId: 0` (sentinel) here.
  Future<void> close({
    required int closedByUserId,
    required String closedByName,
    required int authorizedByUserId,
    required String authorizedByName,
    required double beginningBalance,
    required double endingBalance,
  }) async {
    final data = state.value;
    if (data == null) {
      throw StateError('Cannot close Z-Reading before it has loaded');
    }
    if (data.id != null) {
      throw StateError('Cannot close an already-closed Z-Reading');
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

    await db.cashierAccountingDao.closeZReading(
      zCounter: zCounter,
      periodStart: data.periodStart,
      periodEnd: data.periodEnd,
      closedByUserId: closedByUserId,
      closedByName: closedByName,
      authorizedByUserId: authorizedByUserId,
      authorizedByName: authorizedByName,
      beginningBalance: beginningBalance,
      endingBalance: endingBalance,
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
    );

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
