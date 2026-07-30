import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/entities/report_data.dart';
import '../entities/daily_report_data.dart';
import '../state/daily_report_notifier.dart';
import 'daily_report_screen.dart';

class DailyReportHistoryScreen extends ConsumerWidget {
  const DailyReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(dailyReportHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Report History'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No closed Daily Reports yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder:
                (context, i) => _HistoryTile(
                  row: rows[i],
                  onTap:
                      () => context.push(
                        '/cashier-accounting/daily-report/history/${rows[i].id}',
                      ),
                ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DailyReportsTableData row;
  final VoidCallback onTap;
  const _HistoryTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          title: Text(
            'Daily Report #${row.id}',
            style: AppTextStyles.headingSm,
          ),
          subtitle: Text(
            '${row.cashierName} • ${DateFormat('MMM d, y h:mm a').format(row.generatedAt)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Text(
            'PHP ${row.grossSales.toStringAsFixed(2)}',
            style: AppTextStyles.headingSm,
          ),
        ),
      ),
    );
  }
}

/// Read-only reprint view for a single closed Daily Report history row.
class DailyReportReprintScreen extends ConsumerWidget {
  final int historyId;
  const DailyReportReprintScreen({super.key, required this.historyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowAsync = ref.watch(dailyReportHistoryRowProvider(historyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daily Report #$historyId'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: rowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load Daily Report: $e')),
        data: (row) {
          if (row == null) {
            return const Center(child: Text('Daily Report not found'));
          }
          return DailyReportBody(data: _toDailyReportData(row));
        },
      ),
    );
  }

  DailyReportData _toDailyReportData(DailyReportsTableData row) {
    final salesByProduct =
        (jsonDecode(row.salesByProductJson) as List)
            .map(
              (e) => TopProductData(
                name: e['name'] as String,
                quantity: e['quantity'] as int,
                total: (e['total'] as num).toDouble(),
              ),
            )
            .toList();
    final cashLedger =
        (jsonDecode(row.cashLedgerJson) as List)
            .map(
              (e) => CashLedgerEntry(
                date: DateTime.parse(e['date'] as String),
                total: (e['total'] as num).toDouble(),
              ),
            )
            .toList();

    return DailyReportData(
      id: row.id,
      cashierName: row.cashierName,
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      generatedAt: row.generatedAt,
      grossSales: row.grossSales,
      vatableSales: row.vatableSales,
      vatAmount: row.vatAmount,
      vatExemptSales: row.vatExemptSales,
      netOfTax: row.netOfTax,
      transactionCount: row.transactionCount,
      totalQtySold: row.totalQtySold,
      cashSalesTotal: row.cashSalesTotal,
      cashSalesCount: row.cashSalesCount,
      salesByProduct: salesByProduct,
      cashLedger: cashLedger,
    );
  }
}
