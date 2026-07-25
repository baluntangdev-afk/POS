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
import '../entities/daily_report_data.dart';
import '../state/daily_report_notifier.dart';

class DailyReportScreen extends HookConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dailyReportProvider);
    final isClosing = useState(false);

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
        error: (e, _) => Center(child: Text('Failed to load Daily Report: $e')),
        data: (data) => Column(
          children: [
            Expanded(child: DailyReportBody(data: data)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isClosing.value ? null : handleClose,
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

/// Shared rendering of a [DailyReportData] snapshot, used by both the live
/// [DailyReportScreen] and the read-only history reprint view.
class DailyReportBody extends StatelessWidget {
  final DailyReportData data;
  const DailyReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, y  h:mm a');
    final dayFmt = DateFormat('MMM d, y');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _HeaderCard(data: data, dateFmt: dateFmt),
        const Gap(AppSpacing.lg),
        _SectionHeader('Gross Sales'),
        const Gap(AppSpacing.sm),
        _GrossSalesCard(data: data),
        const Gap(AppSpacing.lg),
        _SectionHeader('VAT Summary'),
        const Gap(AppSpacing.sm),
        _VatSummaryCard(data: data),
        const Gap(AppSpacing.lg),
        _SectionHeader('Others'),
        const Gap(AppSpacing.sm),
        _OthersCard(data: data),
        const Gap(AppSpacing.lg),
        _SectionHeader('Cash Sales'),
        const Gap(AppSpacing.sm),
        _CashSalesCard(data: data),
        const Gap(AppSpacing.lg),
        if (data.salesByProduct.isNotEmpty) ...[
          _SectionHeader('Sales By Product'),
          const Gap(AppSpacing.sm),
          _SalesByProductCard(data: data),
          const Gap(AppSpacing.lg),
        ],
        if (data.cashLedger.isNotEmpty) ...[
          _SectionHeader('Cash Ledger'),
          const Gap(AppSpacing.sm),
          _CashLedgerCard(data: data, dayFmt: dayFmt),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
    );
  }
}

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );

class _HeaderCard extends StatelessWidget {
  final DailyReportData data;
  final DateFormat dateFmt;
  const _HeaderCard({required this.data, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Daily Report', style: AppTextStyles.headingMd),
              ),
              if (data.id != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text('CLOSED #${data.id}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text('LIVE',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text('Cashier: ${data.cashierName}', style: AppTextStyles.bodyMd),
          const Gap(4),
          Text('Period: ${dateFmt.format(data.periodStart)} — ${dateFmt.format(data.periodEnd)}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          const Gap(4),
          Text('Generated: ${dateFmt.format(data.generatedAt)}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _GrossSalesCard extends StatelessWidget {
  final DailyReportData data;
  const _GrossSalesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gross Sales', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          const Gap(2),
          Text('PHP ${data.grossSales.toStringAsFixed(2)}',
              style: AppTextStyles.headingMd.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _VatSummaryCard extends StatelessWidget {
  final DailyReportData data;
  const _VatSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: [
          _row('Vatable Sales', data.vatableSales),
          const Gap(AppSpacing.sm),
          _row('VAT Amount', data.vatAmount),
          const Gap(AppSpacing.sm),
          _row('VAT-Exempt Sales', data.vatExemptSales),
        ],
      ),
    );
  }

  Widget _row(String label, double amount) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          Text('PHP ${amount.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        ],
      );
}

class _OthersCard extends StatelessWidget {
  final DailyReportData data;
  const _OthersCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net of Tax', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('PHP ${data.netOfTax.toStringAsFixed(2)}', style: AppTextStyles.headingSm),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transactions', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('${data.transactionCount}', style: AppTextStyles.headingSm),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty Sold', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('${data.totalQtySold}', style: AppTextStyles.headingSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashSalesCard extends StatelessWidget {
  final DailyReportData data;
  const _CashSalesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash Sales Total', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('PHP ${data.cashSalesTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.headingSm.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash Sales Count', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('${data.cashSalesCount}', style: AppTextStyles.headingSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesByProductCard extends StatelessWidget {
  final DailyReportData data;
  const _SalesByProductCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: data.salesByProduct.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(p.name, style: AppTextStyles.bodyMd, overflow: TextOverflow.ellipsis)),
                Text('x${p.quantity}', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(AppSpacing.sm),
                Text('PHP ${p.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CashLedgerCard extends StatelessWidget {
  final DailyReportData data;
  final DateFormat dayFmt;
  const _CashLedgerCard({required this.data, required this.dayFmt});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: data.cashLedger.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(dayFmt.format(e.date), style: AppTextStyles.bodyMd)),
                Text('PHP ${e.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
