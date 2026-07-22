import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/print_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/sale_receipt_data.dart';
import '../state/ordering_notifier.dart';

class ReceiptScreen extends HookConsumerWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printing = useState(false);
    final receipt = ref.read(orderingProvider.notifier).lastReceipt;

    if (receipt == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: AppColors.textDisabled),
              const Gap(AppSpacing.md),
              Text('No receipt found',
                  style: AppTextStyles.headingSm
                      .copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go('/order'),
                child: const Text('New Order'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/order'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('New Order'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Success banner ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 36),
                ),
                const Gap(AppSpacing.md),
                Text('Payment Successful',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.success)),
                const Gap(4),
                Text(
                  'Sale #${receipt.saleId.toString().padLeft(6, '0')}',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          // ── Receipt card ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Cashier', receipt.cashierName),
                      const Gap(4),
                      _InfoRow('Date',
                          _formatDate(receipt.createdAt)),
                      const Gap(4),
                      _InfoRow('Order Type',
                          _formatSaleType(receipt.saleType)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),

                // Items
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ITEMS',
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.textDisabled,
                              letterSpacing: 0.8)),
                      const Gap(AppSpacing.sm),
                      ...receipt.items.map((item) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('x${item.quantity}',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                                const Gap(AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          style:
                                              AppTextStyles.bodyMd.copyWith(
                                                  fontWeight:
                                                      FontWeight.w500)),
                                      if (item.modifiers.isNotEmpty)
                                        Text(
                                          item.modifiers
                                              .expand((g) => g.selected
                                                  .map((o) => o.name))
                                              .join(', '),
                                          style: AppTextStyles.bodySm
                                              .copyWith(
                                                  color: AppColors
                                                      .textSecondary),
                                        ),
                                      if (item.notes != null &&
                                          item.notes!.isNotEmpty)
                                        Text('Note: ${item.notes}',
                                            style: AppTextStyles.bodySm
                                                .copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                    fontStyle:
                                                        FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        'PHP ${item.lineTotal.toStringAsFixed(2)}',
                                        style: AppTextStyles.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    if (item.discountAmount != null)
                                      Text(
                                          '-PHP ${item.discountAmount!.toStringAsFixed(2)}',
                                          style: AppTextStyles.bodySm
                                              .copyWith(
                                                  color: AppColors.warning)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.divider),

                // Totals
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _TotalRow('Subtotal', receipt.subtotal),
                      if (receipt.totalDiscount > 0)
                        _TotalRow('Discount', -receipt.totalDiscount,
                            color: AppColors.warning),
                      const Gap(4),
                      _TotalRow('TOTAL', receipt.total,
                          large: true, color: AppColors.primary),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.divider),

                // Payment info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAYMENT',
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.textDisabled,
                              letterSpacing: 0.8)),
                      const Gap(AppSpacing.sm),
                      _InfoRow('Method',
                          _formatMethod(receipt.paymentMethod)),
                      if (receipt.paymentMethod == 'cash') ...[
                        const Gap(4),
                        _InfoRow('Tendered',
                            'PHP ${receipt.amountPaid.toStringAsFixed(2)}'),
                        const Gap(4),
                        _InfoRow(
                            'Change',
                            'PHP ${receipt.change.toStringAsFixed(2)}',
                            valueColor: AppColors.success),
                      ] else if (receipt.reference != null) ...[
                        const Gap(4),
                        _InfoRow('Reference', receipt.reference!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),

          // ── Actions ───────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => context.go('/order'),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('New Order'),
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size(double.infinity, AppSpacing.touchPreferred),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          OutlinedButton.icon(
            onPressed: printing.value
                ? null
                : () => _printReceipt(context, receipt, printing),
            icon: printing.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: const Text('Print Receipt'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, AppSpacing.touchMin),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(
    BuildContext context,
    SaleReceiptData receipt,
    ValueNotifier<bool> printing,
  ) async {
    printing.value = true;
    try {
      final ok = await PrintService.printReceipt(receipt);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Receipt printed' : 'No printer configured — go to Settings → Printer Setup',
            ),
            backgroundColor: ok ? null : AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      printing.value = false;
    }
  }

  String _formatDate(DateTime dt) {
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String _formatSaleType(String type) => switch (type) {
        'dine_in' => 'Dine In',
        'take_out' => 'Take Out',
        'delivery' => 'Delivery',
        _ => type,
      };

  String _formatMethod(String method) => switch (method) {
        'cash' => 'Cash',
        'card' => 'Card',
        'ewallet' => 'E-Wallet',
        _ => method,
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool large;
  final Color? color;

  const _TotalRow(this.label, this.amount, {this.large = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: large
                  ? AppTextStyles.headingSm
                  : AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary)),
          Text(
            amount < 0
                ? '-PHP ${(-amount).toStringAsFixed(2)}'
                : 'PHP ${amount.toStringAsFixed(2)}',
            style: large
                ? AppTextStyles.priceMd.copyWith(color: color ?? AppColors.primary)
                : AppTextStyles.bodyMd.copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
