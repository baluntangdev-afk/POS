import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/history_receipt_data.dart';
import 'refund_auth_dialog.dart';

final _refundableItemsProvider =
    FutureProvider.family<List<HistoryReceiptItem>, int>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getRefundableItems(saleId);
});

class RefundScreen extends ConsumerStatefulWidget {
  final int saleId;
  const RefundScreen({super.key, required this.saleId});

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final Map<int, int> _selectedQty = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(_refundableItemsProvider(widget.saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Refund Items')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nothing left to refund on this sale'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final item in items)
                _RefundItemRow(
                  item: item,
                  selectedQty: _selectedQty[item.saleItemId] ?? 0,
                  onChanged: (qty) => setState(() => _selectedQty[item.saleItemId] = qty),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: _submitting || _selectedQty.values.every((q) => q == 0)
                ? null
                : () => _submitRefund(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
            ),
            child: Text(_selectedTotalLabel(itemsAsync.value ?? [])),
          ),
        ),
      ),
    );
  }

  String _selectedTotalLabel(List<HistoryReceiptItem> items) {
    final total = items.fold(0.0, (sum, i) {
      final qty = _selectedQty[i.saleItemId] ?? 0;
      return sum + (qty * i.unitPrice);
    });
    return total > 0 ? 'Refund ₱${total.toStringAsFixed(2)}' : 'Refund Selected Items';
  }

  Future<void> _submitRefund(BuildContext context) async {
    final authorized = await showDialog<bool>(
      context: context,
      builder: (_) => const RefundAuthDialog(),
    );
    if (authorized != true) return;
    if (!context.mounted) return;

    setState(() => _submitting = true);
    final items = ref.read(_refundableItemsProvider(widget.saleId)).value ?? [];
    final refundItems = <({int saleItemId, int qty})>[];
    var total = 0.0;
    for (final item in items) {
      final qty = _selectedQty[item.saleItemId] ?? 0;
      if (qty <= 0) continue;
      refundItems.add((saleItemId: item.saleItemId, qty: qty));
      total += qty * item.unitPrice;
    }

    final db = ref.read(databaseProvider);
    try {
      await db.salesDao.recordRefund(saleId: widget.saleId, total: total, items: refundItems);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund failed: $e')),
      );
      return;
    }

    ref.invalidate(_refundableItemsProvider(widget.saleId));

    if (!context.mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
  }
}

class _RefundItemRow extends StatelessWidget {
  final HistoryReceiptItem item;
  final int selectedQty;
  final ValueChanged<int> onChanged;

  const _RefundItemRow({
    required this.item,
    required this.selectedQty,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.headingSm),
                Text(
                  'Available: ${item.qty} × ₱${item.unitPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: selectedQty > 0 ? () => onChanged(selectedQty - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$selectedQty', style: AppTextStyles.headingSm),
          IconButton(
            onPressed: selectedQty < item.qty ? () => onChanged(selectedQty + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
