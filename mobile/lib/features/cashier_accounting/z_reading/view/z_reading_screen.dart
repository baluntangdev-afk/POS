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
import '../../../transactions/view/refund_auth_dialog.dart';
import '../entities/z_reading_data.dart';
import '../state/z_reading_notifier.dart';

class ZReadingScreen extends HookConsumerWidget {
  const ZReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(zReadingProvider);
    final isClosing = useState(false);
    final canClose = (dataAsync.value?.transactionCount ?? 0) > 0;

    Future<void> handleClose() async {
      final data = dataAsync.value;
      if (data == null || isClosing.value) return;

      final authorized = await showDialog<RefundAuthResult>(
        context: context,
        builder: (_) => const RefundAuthDialog(),
      );
      if (authorized == null) return;
      if (!context.mounted) return;

      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) return;

      isClosing.value = true;
      try {
        await ref.read(zReadingProvider.notifier).close(
              closedByUserId: authState.user.id,
              closedByName: authState.user.name,
              authorizedByUserId: authorized.authorizerId,
              authorizedByName: authorized.authorizerName,
            );
        final printed = await PrintService.printZReading(data);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printed
                ? 'Z-Reading closed and printed'
                : 'Z-Reading closed. Printing failed (check printer connection).'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close Z-Reading: $e')),
        );
      } finally {
        isClosing.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Z-Reading'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/cashier-accounting/z-reading/history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(zReadingProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ReportErrorView(message: 'Failed to load Z-Reading: $e'),
        data: (data) => Column(
          children: [
            Expanded(child: ZReadingReportBody(data: data)),
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
                    label: Text(isClosing.value ? 'Closing…' : 'Close & Print Z-Reading'),
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

/// Shared receipt-style rendering of a [ZReadingData] snapshot, used by both
/// the live [ZReadingScreen] and the read-only history reprint view.
class ZReadingReportBody extends StatelessWidget {
  final ZReadingData data;
  const ZReadingReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ReportReceiptCard(
      children: [
        const ReportStoreHeader(),
        const Gap(12),
        Text(
          'Z-READING',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
        Text(
          'Z-Counter: ${data.zCounter}',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm,
        ),
        const Gap(4),
        ReportStatusBadge(isClosed: data.id != null, closedLabel: 'CLOSED #${data.zCounter}'),
        const Gap(8),
        const ReportDivider(),
        const Gap(6),
        ReportPeriodRow(formatReportPeriod(data.periodStart, data.periodEnd)),
        ReportKeyValueRow('Generated', DateFormat.yMd().add_jm().format(data.generatedAt.toLocal())),
        ReportKeyValueRow('Closed by', data.closedByName),
        if (data.authorizedByName.isNotEmpty) ReportKeyValueRow('Authorized by', data.authorizedByName),
        const Gap(6),
        const ReportDivider(),
        const Gap(6),
        ReportSection(
          title: 'GRAND TOTAL',
          rows: [
            ReportAmountRow('Beginning Balance', data.beginningBalance),
            ReportAmountRow('Ending Balance', data.endingBalance, bold: true),
          ],
        ),
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
            ReportCountRow('Total', data.transactionCount),
            ReportCountRow('Completed', data.completedCount),
            ReportCountRow('Voided', data.voidedCount),
            ReportCountRow('Refunded', data.refundedCount),
          ],
        ),
        ReportSection(
          title: 'DISCOUNT SUMMARY',
          rows: [
            for (final d in data.discounts) ReportAmountRow(d.name, d.amount),
            ReportAmountRow('Total Discounts', data.discountTotal, bold: true),
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
          rows: [ReportCountRow('Total Qty Sold', data.totalQtySold)],
        ),
        if (data.salesByCashier.isNotEmpty)
          ReportSection(
            title: 'SALES BY CASHIER',
            showDividerAfter: false,
            rows: [
              for (final c in data.salesByCashier)
                ReportAmountRow('${c.cashierName} [${c.transactionCount}]', c.total),
            ],
          ),
      ],
    );
  }
}
