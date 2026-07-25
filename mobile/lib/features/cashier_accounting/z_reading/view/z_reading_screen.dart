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
import '../../../transactions/view/refund_auth_dialog.dart';
import '../entities/z_reading_data.dart';
import '../state/z_reading_notifier.dart';

class ZReadingScreen extends HookConsumerWidget {
  const ZReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(zReadingProvider);
    final isClosing = useState(false);

    Future<void> handleClose() async {
      final data = dataAsync.value;
      if (data == null || isClosing.value) return;

      final balances = await showDialog<({double beginning, double ending})>(
        context: context,
        builder: (ctx) => const _BalancesDialog(),
      );
      if (balances == null) return;
      if (!context.mounted) return;

      final authorized = await showDialog<bool>(
        context: context,
        builder: (_) => const RefundAuthDialog(),
      );
      if (authorized != true) return;
      if (!context.mounted) return;

      final authState = ref.read(authNotifierProvider);
      if (authState is! AuthAuthenticated) return;

      isClosing.value = true;
      try {
        await ref.read(zReadingProvider.notifier).close(
              closedByUserId: authState.user.id,
              closedByName: authState.user.name,
              // Known simplification: verifySupervisorPin only returns bool,
              // not which admin matched — see ZReadingNotifier.close docs.
              authorizedByUserId: 0,
              authorizedByName: 'Supervisor',
              beginningBalance: balances.beginning,
              endingBalance: balances.ending,
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
        error: (e, _) => Center(child: Text('Failed to load Z-Reading: $e')),
        data: (data) => Column(
          children: [
            Expanded(child: ZReadingReportBody(data: data)),
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

class _BalancesDialog extends HookWidget {
  const _BalancesDialog();

  @override
  Widget build(BuildContext context) {
    final beginningCtrl = useTextEditingController();
    final endingCtrl = useTextEditingController();
    final error = useState<String?>(null);

    void submit() {
      final beginning = double.tryParse(beginningCtrl.text.trim());
      final ending = double.tryParse(endingCtrl.text.trim());
      if (beginning == null || ending == null) {
        error.value = 'Enter valid numeric amounts for both fields';
        return;
      }
      Navigator.of(context).pop((beginning: beginning, ending: ending));
    }

    return AlertDialog(
      title: const Text('Cash Drawer Balances'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: beginningCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Beginning Balance'),
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: endingCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Ending Balance', errorText: error.value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: submit, child: const Text('Continue')),
      ],
    );
  }
}

/// Shared rendering of a [ZReadingData] snapshot, used by both the live
/// [ZReadingScreen] and the read-only history reprint view.
class ZReadingReportBody extends StatelessWidget {
  final ZReadingData data;
  const ZReadingReportBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, y  h:mm a');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _HeaderCard(data: data, dateFmt: dateFmt),
        const Gap(AppSpacing.lg),
        _SectionHeader('Grand Total'),
        const Gap(AppSpacing.sm),
        _BalancesCard(data: data),
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
        _SectionHeader('Transaction Summary'),
        const Gap(AppSpacing.sm),
        _TransactionSummaryCard(data: data),
        const Gap(AppSpacing.lg),
        _SectionHeader('Discount Summary'),
        const Gap(AppSpacing.sm),
        _AmountCard(label: 'Total Discounts', amount: data.discountTotal),
        const Gap(AppSpacing.lg),
        _SectionHeader('Tax Summary (VAT)'),
        const Gap(AppSpacing.sm),
        _VatCard(data: data),
        const Gap(AppSpacing.lg),
        _SectionHeader('Cash Collected'),
        const Gap(AppSpacing.sm),
        _AmountCard(label: 'Cash Collected', amount: data.cashCollected),
        const Gap(AppSpacing.lg),
        if (data.salesByCashier.isNotEmpty) ...[
          _SectionHeader('Sales By Cashier'),
          const Gap(AppSpacing.sm),
          _SalesByCashierCard(data: data),
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
  final ZReadingData data;
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
                child: Text('Z-Reading Report', style: AppTextStyles.headingMd),
              ),
              if (data.id != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text('CLOSED #${data.zCounter}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text('LIVE — will close as #${data.zCounter}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text('Closed by: ${data.closedByName}', style: AppTextStyles.bodyMd),
          if (data.authorizedByName.isNotEmpty) ...[
            const Gap(4),
            Text('Authorized by: ${data.authorizedByName}', style: AppTextStyles.bodyMd),
          ],
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

class _BalancesCard extends StatelessWidget {
  final ZReadingData data;
  const _BalancesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isClosed = data.id != null;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Beginning Balance', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text(isClosed ? 'PHP ${data.beginningBalance.toStringAsFixed(2)}' : '—',
                    style: AppTextStyles.headingMd),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ending Balance', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text(isClosed ? 'PHP ${data.endingBalance.toStringAsFixed(2)}' : 'Pending — set on close',
                    style: AppTextStyles.headingMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSummaryCard extends StatelessWidget {
  final ZReadingData data;
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
  final ZReadingData data;
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

class _TransactionSummaryCard extends StatelessWidget {
  final ZReadingData data;
  const _TransactionSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(child: _countTile('Completed', data.completedCount, AppColors.success)),
          Expanded(child: _countTile('Voided', data.voidedCount, AppColors.error)),
          Expanded(child: _countTile('Refunded', data.refundedCount, AppColors.warning)),
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

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  const _AmountCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          Text('PHP ${amount.toStringAsFixed(2)}',
              style: AppTextStyles.headingSm.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _VatCard extends StatelessWidget {
  final ZReadingData data;
  const _VatCard({required this.data});

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

class _SalesByCashierCard extends StatelessWidget {
  final ZReadingData data;
  const _SalesByCashierCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: data.salesByCashier.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(c.cashierName, style: AppTextStyles.bodyMd)),
                Text('${c.transactionCount} txn',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                const Gap(AppSpacing.sm),
                Text('PHP ${c.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
