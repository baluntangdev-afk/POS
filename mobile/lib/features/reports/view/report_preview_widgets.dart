import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../settings/state/store_info_notifier.dart';
import '../entities/report_data.dart';

/// White paper-receipt-style card that hosts a cashier report preview,
/// mirroring the look of the order receipt preview (`_ReceiptPreview` in
/// receipt_screen.dart) rather than a grid of separate modern cards.
class ReportReceiptCard extends StatelessWidget {
  const ReportReceiptCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// Store identity block shown at the top of report previews, matching the
/// order-receipt's `_StoreInfoView`.
class ReportStoreHeader extends ConsumerWidget {
  const ReportStoreHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInfo = ref.watch(storeInfoProvider).value;
    final style = AppTextStyles.bodySm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((storeInfo?.storeName ?? '').isNotEmpty)
          Text(storeInfo!.storeName, textAlign: TextAlign.center, style: AppTextStyles.headingSm),
        if ((storeInfo?.address ?? '').isNotEmpty) ...[
          const Gap(4),
          Text(storeInfo!.address, textAlign: TextAlign.center, style: style),
        ],
        if ((storeInfo?.tin ?? '').isNotEmpty) ...[
          const Gap(4),
          Text('TIN: ${storeInfo!.tin}', textAlign: TextAlign.center, style: style),
        ],
      ],
    );
  }
}

/// Receipt-style dashed/starred divider spanning the available width.
class ReportDivider extends StatelessWidget {
  const ReportDivider({this.char = '-', super.key}) : assert(char.length == 1);

  final String char;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6;
        final dashCount = (boxWidth / dashWidth).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Text(char, style: AppTextStyles.bodySm.copyWith(fontSize: 10)),
          ),
        );
      },
    );
  }
}

/// Titled group of rows, followed by a divider.
class ReportSection extends StatelessWidget {
  const ReportSection({
    required this.title,
    required this.rows,
    this.trailingTitle,
    this.showDividerAfter = true,
    super.key,
  });

  final String title;
  final String? trailingTitle;
  final List<Widget> rows;
  final bool showDividerAfter;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.labelMd.copyWith(color: AppColors.primary);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        trailingTitle == null
            ? Text(title, style: style)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(title, style: style, overflow: TextOverflow.ellipsis)),
                  const Gap(AppSpacing.sm),
                  Flexible(child: Text(trailingTitle!, style: style, overflow: TextOverflow.ellipsis)),
                ],
              ),
        const Gap(4),
        ...rows,
        const Gap(8),
        if (showDividerAfter) ...[const ReportDivider(), const Gap(8)],
      ],
    );
  }
}

/// Small bold date label separating ledger entries grouped by calendar date.
class ReportDateGroupHeader extends StatelessWidget {
  const ReportDateGroupHeader(this.date, {super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 1),
      child: Text(
        DateFormat.yMd().format(date),
        style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Label/value row where the value is arbitrary text.
class ReportKeyValueRow extends StatelessWidget {
  const ReportKeyValueRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm),
          const Gap(AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

const noReportTransactionsYetText = 'No transactions yet';

String formatReportPeriod(DateTime? periodStart, DateTime? periodEnd) {
  if (periodStart == null || periodEnd == null) return noReportTransactionsYetText;
  final format = DateFormat.yMd().add_jm();
  return '${format.format(periodStart.toLocal())} - ${format.format(periodEnd.toLocal())}';
}

/// Label-above-value row for a period range, which can wrap onto two lines.
class ReportPeriodRow extends StatelessWidget {
  const ReportPeriodRow(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text('Period', style: AppTextStyles.bodySm)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label/value row where the value is a peso-formatted amount.
class ReportAmountRow extends StatelessWidget {
  const ReportAmountRow(this.label, this.amount, {this.bold = false, this.currency = 'PHP', super.key});

  final String label;
  final double amount;
  final bool bold;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodySm.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
          Text('$currency ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

/// Label/value row where the value is a plain count.
class ReportCountRow extends StatelessWidget {
  const ReportCountRow(this.label, this.value, {super.key});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: AppTextStyles.bodySm, overflow: TextOverflow.ellipsis)),
          Text('$value', style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

/// Centered "LIVE" / "CLOSED #n" status badge shown under the report title.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({required this.isClosed, required this.closedLabel, super.key});

  final bool isClosed;
  final String closedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isClosed ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        isClosed ? closedLabel : 'LIVE',
        style: AppTextStyles.bodySm.copyWith(
          color: isClosed ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Itemized per-payment-method ledger: entries grouped by calendar date, each
/// with a time/reference label, followed by a bold running total. Mirrors
/// kiosk's `PaymentLedgerSection`.
class PaymentLedgerSection extends StatelessWidget {
  const PaymentLedgerSection({required this.ledger, super.key});

  final PaymentLedger ledger;

  @override
  Widget build(BuildContext context) {
    final nameUpper = ledger.displayName.toUpperCase();
    final timeFormat = DateFormat.jm();

    return ReportSection(
      title: '$nameUpper LEDGER',
      rows: [
        for (final group in ledger.entriesByDate) ...[
          ReportDateGroupHeader(group.date),
          for (final entry in group.entries)
            ReportAmountRow(
              '${timeFormat.format(entry.time.toLocal())}  $nameUpper'
              '${entry.reference != null ? ' #${entry.reference}' : ''}',
              entry.amount,
            ),
        ],
        ReportAmountRow('Total $nameUpper [${ledger.count}]', ledger.total, bold: true),
      ],
    );
  }
}

/// Centered error state with a retry button, shared by report preview screens.
class ReportErrorView extends StatelessWidget {
  const ReportErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
    );
  }
}
