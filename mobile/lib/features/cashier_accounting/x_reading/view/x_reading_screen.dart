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
import '../entities/x_reading_data.dart';
import '../state/x_reading_notifier.dart';

class XReadingScreen extends HookConsumerWidget {
  const XReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(xReadingProvider);
    final isClosing = useState(false);

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
        error: (e, _) => Center(child: Text('Failed to load X-Reading: $e')),
        data: (data) => Column(
          children: [
            Expanded(child: XReadingReportBody(data: data)),
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

/// Shared rendering of an [XReadingData] snapshot, used by both the live
/// [XReadingScreen] and the read-only history reprint view.
class XReadingReportBody extends StatelessWidget {
  final XReadingData data;
  const XReadingReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, y  h:mm a');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _HeaderCard(data: data, dateFmt: dateFmt),
        const Gap(AppSpacing.lg),
        _SectionHeader('Sales Summary'),
        const Gap(AppSpacing.sm),
        _SalesSummaryCard(data: data),
        const Gap(AppSpacing.lg),
        if (data.paymentBreakdown.isNotEmpty) ...[
          _SectionHeader('Payment Breakdown'),
          const Gap(AppSpacing.sm),
          _PaymentBreakdownCard(data: data),
          const Gap(AppSpacing.lg),
        ],
        if (data.topProducts.isNotEmpty) ...[
          _SectionHeader('Top Products'),
          const Gap(AppSpacing.sm),
          _TopProductsCard(data: data),
          const Gap(AppSpacing.lg),
        ],
        _SectionHeader('Transaction Summary'),
        const Gap(AppSpacing.sm),
        _TransactionSummaryCard(data: data),
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
  final XReadingData data;
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
                child: Text('X-Reading Report', style: AppTextStyles.headingMd),
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

class _SalesSummaryCard extends StatelessWidget {
  final XReadingData data;
  const _SalesSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Sales', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('PHP ${data.totalSales.toStringAsFixed(2)}',
                    style: AppTextStyles.headingMd.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transactions', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text('${data.transactionCount}', style: AppTextStyles.headingMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBreakdownCard extends StatelessWidget {
  final XReadingData data;
  const _PaymentBreakdownCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: data.paymentBreakdown.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(p.displayName, style: AppTextStyles.bodyMd)),
                Text('PHP ${p.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const Gap(AppSpacing.sm),
                SizedBox(
                  width: 44,
                  child: Text('${p.percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final XReadingData data;
  const _TopProductsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: data.topProducts.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Text('${i + 1}.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                const Gap(AppSpacing.sm),
                Expanded(child: Text(p.name, style: AppTextStyles.bodyMd, overflow: TextOverflow.ellipsis)),
                Text('${p.quantity} sold',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
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

class _TransactionSummaryCard extends StatelessWidget {
  final XReadingData data;
  const _TransactionSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _countTile('Completed', data.transactionCount, AppColors.success),
          ),
          Expanded(
            child: _countTile('Voided', data.voidedCount, AppColors.error),
          ),
          Expanded(
            child: _countTile('Refunded', data.refundedCount, AppColors.warning),
          ),
        ],
      ),
    );
  }

  Widget _countTile(String label, int count, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          const Gap(2),
          Text('$count', style: AppTextStyles.headingMd.copyWith(color: color)),
        ],
      );
}
