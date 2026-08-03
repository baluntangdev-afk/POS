import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../entities/report_data.dart';
import '../entities/sales_health_data.dart';
import 'reports_notifier.dart';

/// Independent from [ReportsNotifier]'s period state — the Sales Health tab
/// keeps its own selected period/date-range, same as kiosk's dashboard vs.
/// health-page filters being separate. Reuses the same [ReportPeriod] enum
/// since the set of periods is identical.
class SalesHealthNotifier extends AsyncNotifier<SalesHealthData> {
  ReportPeriod _period = ReportPeriod.today;
  DateTimeRange? _customRange;
  String _granularity = 'day';

  ReportPeriod get period => _period;
  DateTimeRange? get customRange => _customRange;
  String get granularity => _granularity;

  @override
  Future<SalesHealthData> build() => _load();

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

  Future<SalesHealthData> _load() async {
    final db = ref.watch(databaseProvider);
    final (from, to) = _periodDates();

    final paymentRows = await db.salesDao.getPaymentBreakdown(from, to);
    final salesByCashier = await db.salesDao.getSalesByCashier(from, to);
    final salesByCategory = await db.salesDao.getSalesByProductGroup(from, to);
    final timeSeries = await db.salesDao.getSalesTimeSeries(from, to, granularity: _granularity);

    // Same percentage-mapping formula as ReportsNotifier._load() — kept
    // identical on purpose to avoid two divergent formulas in the codebase.
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

    return SalesHealthData(
      paymentBreakdown: paymentBreakdown,
      salesByCashier: salesByCashier,
      salesByCategory: salesByCategory,
      timeSeries: timeSeries,
      granularity: _granularity,
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

  Future<void> setGranularity(String granularity) async {
    _granularity = granularity;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final salesHealthProvider =
    AsyncNotifierProvider<SalesHealthNotifier, SalesHealthData>(SalesHealthNotifier.new);
