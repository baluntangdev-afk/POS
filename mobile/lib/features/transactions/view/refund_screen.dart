import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../ordering/entities/receipt_item.dart';
import '../state/refund_notifier.dart';
import 'refund_auth_dialog.dart';

class RefundScreen extends ConsumerWidget {
  final int saleId;
  const RefundScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(refundProvider(saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Refund Items')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final refundedQty = data.receipt.refundedQuantities;
          final mainItemEntries = data.receipt.mainItemsWithAddOns;

          if (mainItemEntries.isEmpty) {
            return const Center(child: Text('Nothing left to refund on this sale'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final entry in mainItemEntries)
                _RefundItemRow(
                  item: entry.mainItem,
                  maxQuantity: entry.mainItem.quantity - (refundedQty[entry.mainItem.id] ?? 0),
                  selectedQty: data.form.selectedQuantities[entry.mainItem.id] ?? 0,
                  onToggle: () => ref.read(refundProvider(saleId).notifier).toggleItemSelection(
                        itemId: entry.mainItem.id,
                        maxQuantity: entry.mainItem.quantity - (refundedQty[entry.mainItem.id] ?? 0),
                      ),
                  onQuantityChanged: (qty) => ref
                      .read(refundProvider(saleId).notifier)
                      .changeQuantity(itemId: entry.mainItem.id, quantity: qty),
                ),
              const Gap(AppSpacing.lg),
              Text('REASON', style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.sm),
              TextField(
                onChanged: (v) => ref.read(refundProvider(saleId).notifier).changeReason(v),
                decoration: const InputDecoration(hintText: 'e.g. Wrong item, customer request…'),
              ),
              const Gap(AppSpacing.lg),
              Text('REFUND METHOD',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.sm),
              _RefundMethodSelector(
                selected: data.form.refundMethod,
                onChanged: (m) => ref.read(refundProvider(saleId).notifier).changeRefundMethod(m),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: () => _submitRefund(context, ref, dataAsync.value),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            ),
            child: Text(_selectedTotalLabel(dataAsync.value)),
          ),
        ),
      ),
    );
  }

  String _selectedTotalLabel(RefundData? data) {
    if (data == null) return 'Refund Selected Items';
    final total = data.form.selectedQuantities.entries.fold(0.0, (sum, entry) {
      final item = data.receipt.items.firstWhere((i) => i.id == entry.key);
      return sum + item.unitPrice * entry.value;
    });
    return total > 0 ? 'Refund ₱${total.toStringAsFixed(2)}' : 'Refund Selected Items';
  }

  Future<void> _submitRefund(BuildContext context, WidgetRef ref, RefundData? data) async {
    if (data == null || data.form.selectedQuantities.isEmpty || data.form.reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items and enter a reason before refunding.')),
      );
      return;
    }

    final authorized = await showDialog<RefundAuthResult>(
      context: context,
      builder: (_) => const RefundAuthDialog(),
    );
    if (authorized == null || !context.mounted) return;

    try {
      await ref.read(refundProvider(saleId).notifier).confirmRefund();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund failed: $e')));
      return;
    }

    if (context.mounted) Navigator.of(context).pop();
  }
}

class _RefundItemRow extends StatelessWidget {
  final ReceiptItem item;
  final int maxQuantity;
  final int selectedQty;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChanged;

  const _RefundItemRow({
    required this.item,
    required this.maxQuantity,
    required this.selectedQty,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRefunded = maxQuantity <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isRefunded ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: isRefunded ? null : AppShadows.card,
      ),
      child: Row(
        children: [
          if (isRefunded)
            const SizedBox(width: 48)
          else
            Checkbox(value: selectedQty > 0, onChanged: (_) => onToggle()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: AppTextStyles.headingSm.copyWith(
                    color: isRefunded ? AppColors.textSecondary : null,
                  ),
                ),
                Text(
                  isRefunded
                      ? 'Fully refunded'
                      : 'Available: $maxQuantity × ₱${item.unitPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isRefunded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Refunded',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            )
          else if (selectedQty > 0) ...[
            IconButton(
              onPressed: selectedQty > 1 ? () => onQuantityChanged(selectedQty - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$selectedQty', style: AppTextStyles.headingSm),
            IconButton(
              onPressed: selectedQty < maxQuantity ? () => onQuantityChanged(selectedQty + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _RefundMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RefundMethodSelector({required this.selected, required this.onChanged});

  static const _methods = ['Cash Refund'];
  static const _comingSoonMethods = ['Card Refund', 'E-wallet Refund'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final m in _methods)
          ChoiceChip(
            label: Text(m),
            selected: selected == m,
            onSelected: (_) => onChanged(m),
          ),
        for (final m in _comingSoonMethods)
          ChoiceChip(
            label: Text('$m (Coming soon)'),
            selected: false,
            onSelected: null,
            labelStyle: TextStyle(color: AppColors.textSecondary),
            backgroundColor: AppColors.surface.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
