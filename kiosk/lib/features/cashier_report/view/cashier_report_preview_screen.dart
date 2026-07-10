import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/cashier_x_reading.dart';
import '../state/cashier_report_history_notifier.dart';
import '../state/cashier_x_reading_notifier.dart';
import 'report_preview_widgets.dart';

class CashierReportPreviewScreen extends ConsumerWidget {
  const CashierReportPreviewScreen({super.key, this.historyId});

  /// When set, shows a previously closed X-Reading from history (read-only, Reprint only)
  /// instead of the live in-progress preview.
  final String? historyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyId = this.historyId;
    final state =
        historyId != null
            ? ref.watch(cashierXReadingHistoryDetailProvider(historyId))
            : ref.watch(cashierXReadingNotifierProvider);

    final body = Column(
      children: [
        const TopAppBar(title: 'X-Reading'),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ColorSet.primary)),
            error:
                (error, _) => ReportErrorView(
                  message: 'Failed to load X-Reading',
                  onRetry:
                      historyId != null
                          ? () => ref.invalidate(cashierXReadingHistoryDetailProvider(historyId))
                          : () => ref.read(cashierXReadingNotifierProvider.notifier).load(),
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

  final CashierXReading report;
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
                'X-READING',
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
              ReportKeyValueRow('Cashier', report.cashierName),
              ReportPeriodRow(formatReportPeriod(report.periodStart, report.periodEnd)),
              ReportKeyValueRow(
                'Generated',
                DateFormat.yMd().add_jm().format(report.reportGeneratedAt.toLocal()),
              ),
              const Gap(6),
              const ReportDashedDivider(),
              const Gap(6),
              ReportSection(
                title: 'SALES SUMMARY',
                rows: [
                  for (final entry in report.salesByPaymentMethod)
                    ReportAmountRow(entry.name, entry.amount),
                  ReportAmountRow('Total Sales', report.totalSales, bold: true),
                ],
              ),
              for (final ledger in report.paymentLedgers) _LedgerSection(ledger: ledger),
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
                rows: [
                  ReportAmountRow('Average Sale', report.averageSale),
                  ReportAmountRow('Highest Sale', report.highestSale),
                  ReportAmountRow('Lowest Sale', report.lowestSale),
                  ReportCountRow('Total Qty Sold', report.totalQuantitySold),
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

class _LedgerSection extends StatelessWidget {
  const _LedgerSection({required this.ledger});

  final PaymentLedger ledger;

  @override
  Widget build(BuildContext context) {
    final nameUpper = ledger.name.toUpperCase();
    final timeFormat = DateFormat.jm();

    return ReportSection(
      title: '$nameUpper LEDGER',
      rows: [
        for (final group in ledger.entriesByDate) ...[
          ReportDateGroupHeader(group.date),
          for (final entry in group.entries)
            ReportAmountRow(
              '${timeFormat.format(entry.time.toLocal())}  $nameUpper'
              '${entry.reference != null ? '#${entry.reference}' : ''}',
              entry.amount,
            ),
        ],
        ReportAmountRow('Total $nameUpper [${ledger.count}]', ledger.total, bold: true),
      ],
    );
  }
}

class _PrintButton extends ConsumerWidget {
  const _PrintButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = CashierXReadingNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;
    final hasTransactions = ref.watch(
      cashierXReadingNotifierProvider.select((it) => it.value?.periodStart != null),
    );

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
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
                    return txn.get(cashierXReadingNotifierProvider.notifier).print();
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
        label: Text(isPending ? 'Printing...' : 'Print X-Reading'),
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

  final CashierXReading report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final printAction = CashierXReadingNotifier.printAction;
    final printStatus = ref.watch(printAction);
    final isPending = printStatus is MutationPending;

    ref.listen(printAction, (prev, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
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
                    return txn.get(cashierXReadingNotifierProvider.notifier).reprint(report);
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
        label: Text(isPending ? 'Printing...' : 'Reprint X-Reading'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorSet.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.full)),
        ),
      ),
    );
  }
}
