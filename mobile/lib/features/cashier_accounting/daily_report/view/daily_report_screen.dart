import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/print_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/state/auth_providers.dart';
import '../../../auth/state/auth_state.dart';
import '../../../reports/view/report_preview_widgets.dart';
import '../entities/daily_report_data.dart';
import '../state/daily_report_notifier.dart';
import '../../shared/export_csv_button.dart';

class DailyReportScreen extends HookConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailyReportProvider);
    final isClosing = useState(false);
    final canClose = (dataAsync.value?.transactionCount ?? 0) > 0;

    Future<void> handleClose() async {
      final data = dataAsync.value;
      if (data == null || isClosing.value) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Close Daily Report?'),
          content: const Text(
            'This will close the current period and start a fresh one. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close & Print')),
          ],
        ),
      );
      if (confirmed != true) return;

      isClosing.value = true;
      try {
        await ref.read(dailyReportProvider.notifier).close();
        final printed = await PrintService.printDailyReport(data);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printed
                ? 'Daily Report closed and printed'
                : 'Daily Report closed. Printing failed (check printer connection).'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close Daily Report: $e')),
        );
      } finally {
        isClosing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Report'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          ExportCsvButton(
            periodStart: dataAsync.value?.periodStart,
            onExport: (exp) {
              final authState = ref.read(authNotifierProvider);
              final cashierId = authState is AuthAuthenticated ? authState.user.id : null;
              return exp.exportDailyReport(dataAsync.value!, cashierId: cashierId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/cashier-accounting/daily-report/history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(dailyReportProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ReportErrorView(message: 'Failed to load Daily Report: $e'),
        data: (data) => Column(
          children: [
            Expanded(child: DailyReportBody(data: data)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isClosing.value || !canClose ? null : handleClose,
                    icon: isClosing.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print_rounded),
                    label: Text(isClosing.value ? 'Closing…' : 'Close & Print Daily Report'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared receipt-style rendering of a [DailyReportData] snapshot, used by
/// both the live [DailyReportScreen] and the read-only history reprint view.
class DailyReportBody extends StatelessWidget {
  final DailyReportData data;
  const DailyReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ReportReceiptCard(
      children: [
        const ReportStoreHeader(),
        const Gap(12),
        Text(
          'CASHIER REPORT',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
        const Gap(4),
        ReportStatusBadge(isClosed: data.id != null, closedLabel: 'CLOSED #${data.id}'),
        const Gap(8),
        const ReportDivider(),
        const Gap(6),
        ReportKeyValueRow('Cashier', data.cashierName),
        ReportPeriodRow(formatReportPeriod(data.periodStart, data.periodEnd)),
        ReportKeyValueRow('Generated', DateFormat.yMd().add_jm().format(data.generatedAt.toLocal())),
        const Gap(6),
        const ReportDivider(),
        const Gap(6),
        ReportAmountRow('Gross Sales', data.grossSales, bold: true),
        const Gap(6),
        const ReportDivider(),
        const Gap(6),
        ReportSection(
          title: 'SUMMARY',
          rows: [
            ReportAmountRow('Vatable Sales', data.vatableSales),
            ReportAmountRow('VAT Amount', data.vatAmount),
            ReportAmountRow('VAT Exempt Sales', data.vatExemptSales),
            // No zero-rated concept exists in mobile's local discount model
            // (see SeniorPwdDiscount/PromoDiscount) — shown as 0 to match
            // kiosk's report shape rather than omitting the row entirely.
            const ReportAmountRow('Zero Rated Sales', 0),
          ],
        ),
        ReportSection(
          title: 'OTHERS',
          rows: [
            ReportAmountRow('Net of Tax', data.netOfTax),
            ReportCountRow('No. Transactions', data.transactionCount),
            ReportCountRow('Total Quantity', data.totalQtySold),
          ],
        ),
        ReportSection(
          title: 'CASH SALES',
          rows: [
            ReportAmountRow('Total Cash Sales', data.cashSalesTotal),
            ReportCountRow('No. Cash Sales', data.cashSalesCount),
          ],
        ),
        ReportSection(
          title: 'SALES BY PRODUCT',
          rows: [
            const ReportKeyValueRow('QTY x PRODUCT', 'AMOUNT'),
            const Gap(2),
            if (data.salesByProduct.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('No products sold today',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              )
            else
              for (final p in data.salesByProduct) ReportAmountRow('${p.quantity} ${p.name}', p.total),
            const Gap(4),
            ReportAmountRow('TOTAL', data.grossSales, bold: true),
          ],
        ),
        ReportSection(
          title: 'CASH LEDGER',
          showDividerAfter: false,
          rows: [
            for (final group in data.cashLedgerSummariesByDate) ...[
              ReportDateGroupHeader(group.date),
              ReportAmountRow(
                '${DateFormat.jm().format(group.entries.first.time.toLocal())}'
                ' - ${DateFormat.jm().format(group.entries.last.time.toLocal())}  CASH',
                group.total,
              ),
            ],
            ReportAmountRow('***** TOTAL CASH', data.cashSalesTotal, bold: true),
          ],
        ),
      ],
    );
  }
}
