import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/report_data.dart';

enum ReportPeriod { today, week, month, custom }

class ReportsNotifier extends AsyncNotifier<ReportData> {
  ReportPeriod _period = ReportPeriod.today;
  DateTimeRange? _customRange;

  ReportPeriod get period => _period;
  DateTimeRange? get customRange => _customRange;

  @override
  Future<ReportData> build() => _load();

  (DateTime, DateTime) _periodDates() {
    final now = DateTime.now();
    return switch (_period) {
      ReportPeriod.today => (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      ReportPeriod.week => (
          now.subtract(Duration(days: now.weekday - 1))
              .copyWith(hour: 0, minute: 0, second: 0),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      ReportPeriod.month => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      ReportPeriod.custom => (
          _customRange!.start,
          _customRange!.end.copyWith(hour: 23, minute: 59, second: 59),
        ),
    };
  }

  Future<ReportData> _load() async {
    final db = ref.watch(databaseProvider);
    final (from, to) = _periodDates();

    final totalSales = await db.salesDao.getTotalSalesForDateRange(from, to);
    final transactionCount = await db.salesDao.getTransactionCountForDateRange(from, to);
    final paymentRows = await db.salesDao.getPaymentBreakdown(from, to);
    final topProductRows = await db.salesDao.getTopProducts(from, to, limit: 5);
    final recentSales = await db.salesDao.getSalesByDateRange(from, to);

    final totalPaid =
        paymentRows.fold(0.0, (s, r) => s + (r['total'] as double? ?? 0));

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

    return ReportData(
      totalSales: totalSales,
      transactionCount: transactionCount,
      averageOrder:
          transactionCount > 0 ? totalSales / transactionCount : 0,
      paymentBreakdown: paymentBreakdown,
      topProducts: topProducts,
      recentSales: recentSales.take(20).toList(),
      from: from,
      to: to,
    );
  }

  Future<void> setPeriod(ReportPeriod period, {DateTimeRange? customRange}) async {
    _period = period;
    if (period == ReportPeriod.custom) _customRange = customRange;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final reportsProvider =
    AsyncNotifierProvider<ReportsNotifier, ReportData>(ReportsNotifier.new);
