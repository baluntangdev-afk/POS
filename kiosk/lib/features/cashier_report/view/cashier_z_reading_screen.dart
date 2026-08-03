import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/supervisor_authorization_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/z_reading.dart';
import '../state/cashier_report_history_notifier.dart';
import '../state/cashier_x_reading_notifier.dart' show cashierReportPosTerminalProvider;
import '../state/z_reading_notifier.dart';
import 'report_preview_widgets.dart';

class CashierZReadingScreen extends ConsumerWidget {
  const CashierZReadingScreen({super.key, this.historyId});

  /// When set, shows a previously closed Z-Reading from history (read-only, Reprint only)
  /// instead of the live in-progress preview.
  final String? historyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyId = this.historyId;
    final state =
        historyId != null
            ? ref.watch(zReadingHistoryDetailProvider(historyId))
            : ref.watch(zReadingNotifierProvider);

    final body = Column(
      children: [
        const TopAppBar(title: 'Z-Reading'),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ColorSet.primary)),
            error:
                (error, _) => ReportErrorView(
                  message: 'Failed to load Z-Reading',
                  onRetry:
                      historyId != null
                          ? () => ref.invalidate(zReadingHistoryDetailProvider(historyId))
                          : () => ref.read(zReadingNotifierProvider.notifier).load(),
                ),
            data: (report) {
              if (report == null) return const SizedBox.shrink();
              return _ReportPreview(report: report, isHistory: historyId != null);
            },
          ),
        ),
      ],
    );

    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _ReportPreview extends ConsumerWidget {
  const _ReportPreview({required this.report, required this.isHistory});

  final ZReading report;
  final bool isHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final terminalAsync = ref.watch(cashierReportPosTerminalProvider);

    return Column(
      children: [
        Expanded(
          child: ReportReceiptCard(
            children: [
              if (terminalAsync case AsyncData(:final value)) ...[
                ReportStoreHeader(terminal: value),
                const Gap(12),
              ],
              Text(
                'Z-READING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                  fontWeight: FontWeight.w800,
                  color: ColorSet.primary,
                ),
              ),
              if (report.zCounter != null)
                Text(
                  'Z-Counter: ${report.zCounter}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12)),
                ),
              const Gap(8),
              const ReportDashedDivider(),
              const Gap(6),
              ReportPeriodRow(formatReportPeriod(report.periodStart, report.periodEnd)),
              ReportKeyValueRow(
                'Generated',
                DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()),
              ),
              if (report.closedByName != null)
                ReportKeyValueRow('Closed by', report.closedByName!),
              if (report.authorizedByName != null)
                ReportKeyValueRow('Authorized by', report.authorizedByName!),
              const Gap(6),
              const ReportDashedDivider(),
              const Gap(6),
              ReportSection(
                title: 'GRAND TOTAL',
                rows: [
                  ReportAmountRow('Beginning Balance', report.beginningBalance),
                  ReportAmountRow('Ending Balance', report.endingBalance, bold: true),
                ],
              ),
              ReportSection(
                title: 'SALES SUMMARY',
                rows: [
                  for (final entry in report.salesByPaymentMethod)
                    ReportAmountRow(entry.name, entry.amount),
                  ReportAmountRow('Total Sales', report.totalSales, bold: true),
                ],
              ),
              for (final ledger in report.paymentLedgers) PaymentLedgerSection(ledger: ledger),
              ReportSection(
                title: 'QTY x PRODUCT',
                trailingTitle: 'AMOUNT',
                rows: [
                  for (final entry in report.salesByItem)
                    ReportAmountRow('${entry.quantity} ${entry.name}', entry.amount),
                ],
              ),
              ReportSection(
                title: 'TRANSACTION SUMMARY',
                rows: [
                  ReportCountRow('Total', report.totalTransactions),
                  ReportCountRow('Completed', report.completedTransactions),
                  ReportCountRow('Voided', report.voidedTransactions),
                  ReportCountRow('Refunded', report.refundedTransactions),
                ],
              ),
              ReportSection(
                title: 'DISCOUNT SUMMARY',
                rows: [
                  for (final entry in report.discounts) ReportAmountRow(entry.name, entry.amount),
                  ReportAmountRow('Total Discounts', report.totalDiscounts, bold: true),
                ],
              ),
              ReportSection(
                title: 'TAX SUMMARY',
                rows: [
                  ReportAmountRow('VAT Sales', report.vatSales),
                  ReportAmountRow('VAT Amount', report.vatAmount),
                  ReportAmountRow('VAT-Exempt Sales', report.vatExemptSales),
                ],
              ),
              ReportSection(
                title: 'CASH COLLECTED',
                rows: [ReportAmountRow('Cash Collected', report.cashCollected, bold: true)],
              ),
              ReportSection(
                title: 'OTHER SUMMARY',
                rows: [ReportCountRow('Total Qty Sold', report.totalQuantitySold)],
              ),
              ReportSection(
                title: 'SALES BY CASHIER',
                rows: [
                  for (final entry in report.salesByCashier)
                    ReportAmountRow(
                      '${entry.cashierName} [${entry.transactionCount}]',
                      entry.salesTotal,
                    ),
                ],
                showDividerAfter: false,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            r.value<double>(kiosk: 48, tablet: 32, phone: 20),
            0,
            r.value<double>(kiosk: 48, tablet: 32, phone: 20),
            r.value<double>(kiosk: 24, tablet: 20, phone: 16),
          ),
          child: isHistory ? _ReprintButton(report: report) : const _PrintButton(),
        ),
      ],
    );
  }
}

class _PrintButton extends ConsumerWidget {
  const _PrintButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = ZReadingNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;
    final hasTransactions = ref.watch(
      zReadingNotifierProvider.select((it) => it.value?.periodStart != null),
    );

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
      if (next is MutationSuccess) {
        showMessageDialog(
          context,
          type: DialogType.success,
          title: 'Report Printed',
          message: 'The Z-Reading report has been sent to the printer.',
        );
      }
    });

    Future<void> onPressed() async {
      final result = await SupervisorAuthorizationDialog.show(
        context,
        title: 'Z-Reading Close Authorization',
        warningMessage:
            "Closing a Z-Reading permanently resets the day's totals. Admin or supervisor "
            'authorization is required to proceed.',
        ctaLabel: 'Authorize Close',
        ctaIcon: Icons.lock_open_rounded,
      );
      if (result == null || !context.mounted) return;

      printAction
          .run(ref, (txn) {
            return txn
                .get(zReadingNotifierProvider.notifier)
                .close(authorizerId: result.authorizerId, pin: result.pin);
          })
          .ignore();
    }

    return SizedBox(
      width: double.infinity,
      height: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
      child: FilledButton.icon(
        onPressed: isPending || !hasTransactions ? null : onPressed,
        icon:
            isPending
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                : const Icon(Icons.print_rounded),
        label: Text(isPending ? 'Printing...' : 'Print Z-Reading'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
        ),
      ),
    );
  }
}

class _ReprintButton extends ConsumerWidget {
  const _ReprintButton({required this.report});

  final ZReading report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = ZReadingNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
      if (next is MutationSuccess) {
        showMessageDialog(
          context,
          type: DialogType.success,
          title: 'Report Reprinted',
          message: 'The Z-Reading report has been sent to the printer.',
        );
      }
    });

    return SizedBox(
      width: double.infinity,
      height: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
      child: FilledButton.icon(
        onPressed:
            isPending
                ? null
                : () {
                  printAction.run(ref, (txn) {
                    return txn.get(zReadingNotifierProvider.notifier).reprint(report);
                  }).ignore();
                },
        icon:
            isPending
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                : const Icon(Icons.print_rounded),
        label: Text(isPending ? 'Printing...' : 'Reprint Z-Reading'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
        ),
      ),
    );
  }
}
