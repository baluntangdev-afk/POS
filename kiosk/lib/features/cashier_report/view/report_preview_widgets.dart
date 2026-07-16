import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../gen/assets.gen.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../entities/cashier_x_reading.dart';

/// White receipt-style card that hosts a report preview, centered and scrollable.
class ReportReceiptCard extends StatelessWidget {
  const ReportReceiptCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: r.value<double>(kiosk: 400, tablet: 360, phone: 320),
          margin: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 24, tablet: 20, phone: 14)),
          padding: EdgeInsets.symmetric(
            horizontal: r.value<double>(kiosk: 20, tablet: 18, phone: 14),
            vertical: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(POSRadius.xs),
            boxShadow: POSShadow.card,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Store identity block (logo, legal name, address, TIN) shown at the top of report previews.
class ReportStoreHeader extends StatelessWidget {
  const ReportStoreHeader({required this.terminal, super.key});

  final PosTerminalDto terminal;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Assets.images.cartivoLogo.image(height: r.value<double>(kiosk: 32, tablet: 28, phone: 24)),
        Gap(r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
        Text(
          terminal.legalName?.trim().isNotEmpty ?? false
              ? terminal.legalName!.trim()
              : 'POS Terminal',
          textAlign: TextAlign.center,
          style: style,
        ),
        Text(terminal.address.trim(), textAlign: TextAlign.center, style: style),
        const Gap(8),
        Text('TIN: ${terminal.tinNumber}', textAlign: TextAlign.center, style: style),
      ],
    );
  }
}

/// Titled group of rows with an optional trailing dashed divider. When [trailingTitle] is
/// given, the title renders as a two-column table header (e.g. "QTY x PRODUCT" / "AMOUNT")
/// instead of a single left-aligned label.
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
    final r = context.responsive;
    final style = TextStyle(
      fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 11),
      fontWeight: FontWeight.w700,
      color: ColorSet.primary,
      letterSpacing: 0.4,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        trailingTitle == null
            ? Align(alignment: Alignment.centerLeft, child: Text(title, style: style))
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(title, style: style), Text(trailingTitle!, style: style)],
              ),
        const Gap(4),
        ...rows,
        const Gap(6),
        if (showDividerAfter) ...[const ReportDashedDivider(), const Gap(6)],
      ],
    );
  }
}

/// Small bold date label used to separate ledger entries grouped by calendar date.
class ReportDateGroupHeader extends StatelessWidget {
  const ReportDateGroupHeader(this.date, {super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 1),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          DateFormat.yMd().format(date),
          style: TextStyle(
            fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 11),
            fontWeight: FontWeight.w700,
            color: POSColors.textSecondary,
          ),
        ),
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
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

const noReportTransactionsYetText = 'No transactions yet';

/// Formats the earliest/latest transaction covered by a report as a single range string,
/// or a placeholder when the cashier has no unreported transactions yet.
String formatReportPeriod(DateTime? periodStart, DateTime? periodEnd) {
  if (periodStart == null || periodEnd == null) return noReportTransactionsYetText;
  final format = DateFormat.yMd().add_jm();
  return '${format.format(periodStart.toLocal())} - ${format.format(periodEnd.toLocal())}';
}

/// Label-above-value row for the report's covered-transaction period, which can be long
/// enough (spanning two calendar days) to overflow a side-by-side [ReportKeyValueRow].
class ReportPeriodRow extends StatelessWidget {
  const ReportPeriodRow(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final labelStyle = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    final valueStyle = labelStyle.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text('Period', style: labelStyle)),
          Expanded(child: Text(value, style: valueStyle, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// Label/value row where the value is a peso-formatted amount.
class ReportAmountRow extends StatelessWidget {
  const ReportAmountRow(this.label, this.amount, {this.bold = false, super.key});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = TextStyle(
      fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12),
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    final decimalAmount = Decimal.parse(amount.toStringAsFixed(2));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
          Text(decimalAmount.pesoFormatted, style: style),
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
    final r = context.responsive;
    final style = TextStyle(fontSize: r.value<double>(kiosk: 13, tablet: 13, phone: 12));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text('$value', style: style)],
      ),
    );
  }
}

/// Receipt-style dashed divider spanning the available width.
class ReportDashedDivider extends StatelessWidget {
  const ReportDashedDivider({super.key});

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
            (_) => const Text('-', style: TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }
}

/// Centered error state with a retry button, shared by report preview screens.
class ReportErrorView extends StatelessWidget {
  const ReportErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: ColorSet.danger, size: 40),
          const Gap(12),
          Text(message, style: const TextStyle(color: POSColors.textPrimary)),
          const Gap(12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Itemized per-payment-method ledger: entries grouped by calendar date, each with a
/// time/reference label, followed by a bold running total. Shared by X-Reading and Z-Reading.
class PaymentLedgerSection extends StatelessWidget {
  const PaymentLedgerSection({required this.ledger, super.key});

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
