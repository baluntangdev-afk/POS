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
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier_daily_report.dart';
import '../state/cashier_daily_report_notifier.dart';
import '../state/cashier_report_history_notifier.dart';
import '../state/cashier_x_reading_notifier.dart';
import 'report_preview_widgets.dart';

class CashierDailyReportScreen extends ConsumerWidget {
  const CashierDailyReportScreen({super.key, this.historyId});

  /// When set, shows a previously closed daily report from history (read-only, Reprint only)
  /// instead of the live in-progress preview.
  final String? historyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyId = this.historyId;
    final state =
        historyId != null
            ? ref.watch(cashierDailyReportHistoryDetailProvider(historyId))
            : ref.watch(cashierDailyReportNotifierProvider);

    final body = Column(
      children: [
        const TopAppBar(title: 'Cashier Daily Report'),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ColorSet.primary)),
            error:
                (error, _) => ReportErrorView(
                  message: 'Failed to load Cashier Daily Report',
                  onRetry:
                      historyId != null
                          ? () =>
                              ref.invalidate(cashierDailyReportHistoryDetailProvider(historyId))
                          : () => ref.read(cashierDailyReportNotifierProvider.notifier).load(),
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

  final CashierDailyReport report;
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
                'CASHIER REPORT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                  fontWeight: FontWeight.w800,
                  color: ColorSet.primary,
                ),
              ),
              const Gap(8),
              const ReportDashedDivider(),
              const Gap(6),
              ReportKeyValueRow('Terminal', report.terminalName),
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportPeriodRow(formatReportPeriod(report.periodStart, report.periodEnd)),
              ReportKeyValueRow(
                'Generated',
                DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()),
              ),
              const Gap(6),
              const ReportDashedDivider(),
              const Gap(6),
              ReportAmountRow('Gross Sales', report.grossSales, bold: true),
              const Gap(6),
              const ReportDashedDivider(),
              const Gap(6),
              ReportSection(
                title: 'SUMMARY',
                rows: [
                  ReportAmountRow('Vatable Sales', report.vatableSales),
                  ReportAmountRow('VAT Amount', report.vatAmount),
                  ReportAmountRow('VAT Exempt Sales', report.vatExemptSales),
                  ReportAmountRow('Zero Rated Sales', report.zeroRatedSales),
                ],
              ),
              ReportSection(
                title: 'OTHERS',
                rows: [
                  ReportAmountRow('Net of Tax', report.netOfTax),
                  ReportCountRow('No. Transactions', report.transactionCount),
                  ReportCountRow('Total Quantity', report.totalQuantity),
                ],
              ),
              ReportSection(
                title: 'CASH SALES',
                rows: [
                  ReportAmountRow('Total Cash Sales', report.totalCashSales),
                  ReportCountRow('No. Cash Sales', report.cashSalesCount),
                ],
              ),
              ReportSection(
                title: 'SALES BY PRODUCT',
                rows: [
                  const ReportKeyValueRow('QTY x PRODUCT', 'AMOUNT'),
                  const Gap(2),
                  if (report.salesByProduct.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'No products sold today',
                        style: TextStyle(fontSize: 12, color: POSColors.textTertiary),
                      ),
                    )
                  else
                    for (final line in report.salesByProduct)
                      ReportAmountRow('${line.quantity} ${line.productName}', line.amount),
                  const Gap(4),
                  ReportAmountRow('TOTAL', report.grossSales, bold: true),
                ],
              ),
              ReportSection(
                title: 'CASH LEDGER',
                rows: [
                  for (final summary in report.cashLedgerSummariesByDate) ...[
                    ReportDateGroupHeader(summary.date),
                    ReportAmountRow(
                      '${DateFormat.jm().format(summary.start.toLocal())}'
                      ' - ${DateFormat.jm().format(summary.end.toLocal())}  CASH',
                      summary.amount,
                    ),
                  ],
                  ReportAmountRow('***** TOTAL CASH', report.totalCashSales, bold: true),
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
    final printAction = CashierDailyReportNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;
    final hasTransactions = ref.watch(
      cashierDailyReportNotifierProvider.select((it) => it.value?.periodStart != null),
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
          message: 'The cashier daily report has been sent to the printer.',
        );
      }
    });

    return SizedBox(
      width: double.infinity,
      height: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
      child: FilledButton.icon(
        onPressed:
            isPending || !hasTransactions
                ? null
                : () {
                  printAction.run(ref, (txn) {
                    return txn.get(cashierDailyReportNotifierProvider.notifier).print();
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
        label: Text(isPending ? 'Printing...' : 'Print Cashier Report'),
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

  final CashierDailyReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = CashierDailyReportNotifier.printAction;
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
          message: 'The cashier daily report has been sent to the printer.',
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
                    return txn.get(cashierDailyReportNotifierProvider.notifier).reprint(report);
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
        label: Text(isPending ? 'Printing...' : 'Reprint Cashier Report'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
        ),
      ),
    );
  }
}
