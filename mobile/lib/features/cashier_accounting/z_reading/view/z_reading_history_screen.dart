import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/entities/report_data.dart';
import '../entities/z_reading_data.dart';
import '../../shared/export_csv_button.dart';
import '../state/z_reading_notifier.dart';
import 'z_reading_screen.dart';

class ZReadingHistoryScreen extends ConsumerWidget {
  const ZReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(zReadingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Z-Reading History'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load history: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No closed Z-Readings yet'));
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
                        '/cashier-accounting/z-reading/history/${rows[i].id}',
                      ),
                ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ZReadingsTableData row;
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
            'Z-Reading #${row.zCounter}',
            style: AppTextStyles.headingSm,
          ),
          subtitle: Text(
            '${row.closedByName} • ${DateFormat('MMM d, y h:mm a').format(row.generatedAt)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Text(
            'PHP ${row.totalSales.toStringAsFixed(2)}',
            style: AppTextStyles.headingSm,
          ),
        ),
      ),
    );
  }
}

/// Read-only reprint view for a single closed Z-Reading history row.
class ZReadingReprintScreen extends HookConsumerWidget {
  final int historyId;
  const ZReadingReprintScreen({super.key, required this.historyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowAsync = ref.watch(zReadingHistoryRowProvider(historyId));
    final isPrinting = useState(false);

    Future<void> handlePrint(ZReadingData data) async {
      if (isPrinting.value) return;
      isPrinting.value = true;
      try {
        final printed = await PrintService.printZReading(data);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printed ? 'Z-Reading sent to printer' : 'Printing failed (check printer connection).'),
          ),
        );
      } finally {
        isPrinting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Z-Reading #$historyId'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          ExportCsvButton(
            periodStart: rowAsync.value?.periodStart,
            onExport: (exp) => exp.exportZReading(_toZReadingData(rowAsync.value!)),
          ),
          IconButton(
            icon: isPrinting.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded),
            tooltip: 'Reprint',
            onPressed: rowAsync.value == null || isPrinting.value
                ? null
                : () => handlePrint(_toZReadingData(rowAsync.value!)),
          ),
        ],
      ),
      body: rowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load Z-Reading: $e')),
        data: (row) {
          if (row == null) {
            return const Center(child: Text('Z-Reading not found'));
          }
          return ZReadingReportBody(data: _toZReadingData(row));
        },
      ),
    );
  }

  ZReadingData _toZReadingData(ZReadingsTableData row) {
    final paymentBreakdown =
        (jsonDecode(row.paymentBreakdownJson) as List)
            .map(
              (e) => PaymentBreakdown(
                method: e['method'] as String,
                total: (e['total'] as num).toDouble(),
                percentage: (e['percentage'] as num).toDouble(),
              ),
            )
            .toList();
    final salesByCashier =
        (jsonDecode(row.salesByCashierJson) as List)
            .map(
              (e) => CashierSalesBreakdown(
                cashierName: e['cashierName'] as String,
                total: (e['total'] as num).toDouble(),
                transactionCount: e['transactionCount'] as int,
              ),
            )
            .toList();
    final discounts =
        (jsonDecode(row.discountsJson) as List)
            .map((e) => NameAmount(name: e['name'] as String, amount: (e['amount'] as num).toDouble()))
            .toList();
    final paymentLedgers = PaymentLedger.decodeList(row.paymentLedgersJson);

    return ZReadingData(
      id: row.id,
      zCounter: row.zCounter,
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      generatedAt: row.generatedAt,
      closedByName: row.closedByName,
      authorizedByName: row.authorizedByName,
      beginningBalance: row.beginningBalance,
      endingBalance: row.endingBalance,
      totalSales: row.totalSales,
      vatableSales: row.vatableSales,
      vatAmount: row.vatAmount,
      vatExemptSales: row.vatExemptSales,
      transactionCount: row.transactionCount,
      completedCount: row.completedCount,
      voidedCount: row.voidedCount,
      refundedCount: row.refundedCount,
      discountTotal: row.discountTotal,
      cashCollected: row.cashCollected,
      totalQtySold: row.totalQtySold,
      paymentBreakdown: paymentBreakdown,
      paymentLedgers: paymentLedgers,
      salesByCashier: salesByCashier,
      discounts: discounts,
    );
  }
}
