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
import '../entities/x_reading_data.dart';
import '../state/x_reading_notifier.dart';
import '../../shared/export_csv_button.dart';

class XReadingScreen extends HookConsumerWidget {
  const XReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(xReadingProvider);
    final isClosing = useState(false);
    final canClose = (dataAsync.value?.transactionCount ?? 0) > 0;

    Future<void> handleClose() async {
      final data = dataAsync.value;
      if (data == null || isClosing.value) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Close X-Reading?'),
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
        await ref.read(xReadingProvider.notifier).close();
        final printed = await PrintService.printXReading(data);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printed
                ? 'X-Reading closed and printed'
                : 'X-Reading closed. Printing failed (check printer connection).'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close X-Reading: $e')),
        );
      } finally {
        isClosing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('X-Reading'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          ExportCsvButton(
            periodStart: dataAsync.value?.periodStart,
            onExport: (exp) {
              final authState = ref.read(authNotifierProvider);
              final cashierId = authState is AuthAuthenticated ? authState.user.id : null;
              return exp.exportXReading(dataAsync.value!, cashierId: cashierId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/cashier-accounting/x-reading/history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(xReadingProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ReportErrorView(message: 'Failed to load X-Reading: $e'),
        data: (data) => Column(
          children: [
            Expanded(child: XReadingReportBody(data: data)),
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
                    label: Text(isClosing.value ? 'Closing…' : 'Close & Print X-Reading'),
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

/// Shared receipt-style rendering of an [XReadingData] snapshot, used by both
/// the live [XReadingScreen] and the read-only history reprint view.
class XReadingReportBody extends StatelessWidget {
  final XReadingData data;
  const XReadingReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ReportReceiptCard(
      children: [
        const ReportStoreHeader(),
        const Gap(12),
        Text(
          'X-READING',
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
        ReportSection(
          title: 'SALES SUMMARY',
          rows: [
            for (final p in data.paymentBreakdown) ReportAmountRow(p.displayName, p.total),
            ReportAmountRow('Total Sales', data.totalSales, bold: true),
          ],
        ),
        for (final ledger in data.paymentLedgers) PaymentLedgerSection(ledger: ledger),
        ReportSection(
          title: 'TRANSACTION SUMMARY',
          rows: [
            ReportCountRow('Completed', data.transactionCount),
            ReportCountRow('Voided', data.voidedCount),
            ReportCountRow('Refunded', data.refundedCount),
          ],
        ),
        ReportSection(
          title: 'DISCOUNT SUMMARY',
          rows: [
            for (final d in data.discounts) ReportAmountRow(d.name, d.amount),
            ReportAmountRow('Total Discounts', data.totalDiscounts, bold: true),
          ],
        ),
        ReportSection(
          title: 'TAX SUMMARY',
          rows: [
            ReportAmountRow('VAT Sales', data.vatableSales),
            ReportAmountRow('VAT Amount', data.vatAmount),
            ReportAmountRow('VAT-Exempt Sales', data.vatExemptSales),
          ],
        ),
        ReportSection(
          title: 'CASH COLLECTED',
          rows: [ReportAmountRow('Cash Collected', data.cashCollected, bold: true)],
        ),
        ReportSection(
          title: 'OTHER SUMMARY',
          rows: [
            ReportAmountRow('Average Sale', data.averageSale),
            ReportAmountRow('Highest Sale', data.highestSale),
            ReportAmountRow('Lowest Sale', data.lowestSale),
          ],
          showDividerAfter: false,
        ),
      ],
    );
  }
}
