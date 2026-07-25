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
import '../entities/x_reading_data.dart';
import '../state/x_reading_notifier.dart';
import 'x_reading_screen.dart';

class XReadingHistoryScreen extends ConsumerWidget {
  const XReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(xReadingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('X-Reading History'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No closed X-Readings yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _HistoryTile(
              row: rows[i],
              onTap: () => context.push('/cashier-accounting/x-reading/history/${rows[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final XReadingsTableData row;
  final VoidCallback onTap;
  const _HistoryTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 1)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text('X-Reading #${row.id}', style: AppTextStyles.headingSm),
        subtitle: Text(
          '${row.cashierName} • ${DateFormat('MMM d, y h:mm a').format(row.generatedAt)}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Text('PHP ${row.totalSales.toStringAsFixed(2)}', style: AppTextStyles.headingSm),
      ),
    );
  }
}

/// Read-only reprint view for a single closed X-Reading history row.
class XReadingReprintScreen extends ConsumerWidget {
  final int historyId;
  const XReadingReprintScreen({super.key, required this.historyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowAsync = ref.watch(xReadingHistoryRowProvider(historyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('X-Reading #$historyId'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: rowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load X-Reading: $e')),
        data: (row) {
          if (row == null) {
            return const Center(child: Text('X-Reading not found'));
          }
          return XReadingReportBody(data: _toXReadingData(row));
        },
      ),
    );
  }

  XReadingData _toXReadingData(XReadingsTableData row) {
    final paymentBreakdown = (jsonDecode(row.paymentBreakdownJson) as List)
        .map((e) => PaymentBreakdown(
              method: e['method'] as String,
              total: (e['total'] as num).toDouble(),
              percentage: (e['percentage'] as num).toDouble(),
            ))
        .toList();
    final topProducts = (jsonDecode(row.topProductsJson) as List)
        .map((e) => TopProductData(
              name: e['name'] as String,
              quantity: e['quantity'] as int,
              total: (e['total'] as num).toDouble(),
            ))
        .toList();

    return XReadingData(
      id: row.id,
      cashierName: row.cashierName,
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      generatedAt: row.generatedAt,
      totalSales: row.totalSales,
      transactionCount: row.transactionCount,
      voidedCount: row.voidedCount,
      refundedCount: row.refundedCount,
      paymentBreakdown: paymentBreakdown,
      topProducts: topProducts,
    );
  }
}
