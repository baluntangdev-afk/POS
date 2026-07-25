import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/history_receipt_data.dart';
import '../state/transactions_notifier.dart';
import 'refund_screen.dart';

final _historyReceiptProvider =
    FutureProvider.family<HistoryReceiptData?, int>((ref, saleId) {
  final db = ref.watch(databaseProvider);
  return db.salesDao.getHistoryReceipt(saleId);
});

class TransactionDetailScreen extends ConsumerWidget {
  final int saleId;
  const TransactionDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_historyReceiptProvider(saleId));
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Transaction #${saleId.toString().padLeft(6, '0')}')),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (receipt) {
          if (receipt == null) return const Center(child: Text('Transaction not found'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(DateFormat('MMM d, yyyy • h:mm a').format(receipt.createdAt),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              for (final item in receipt.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: item.modifiers.isEmpty ? null : Text(item.modifiers.join(', ')),
                  trailing: Text('${item.qty} × ₱${item.unitPrice.toStringAsFixed(2)}'),
                ),
              const Divider(),
              _SummaryRow('Subtotal', receipt.subtotal),
              _SummaryRow('Discount', -receipt.discount),
              _SummaryRow('Total', receipt.total, bold: true),
              const SizedBox(height: AppSpacing.xl),
              if (isAdmin) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RefundScreen(saleId: saleId)),
                  ),
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Refund Items'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmVoid(context, ref),
                  icon: const Icon(Icons.block),
                  label: const Text('Void Transaction'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmVoid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void this transaction?'),
        content: const Text('This cannot be undone. The sale will be marked voided.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(transactionsProvider.notifier).voidTransaction(saleId);
    ref.invalidate(_historyReceiptProvider(saleId));
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.headingSm : AppTextStyles.bodySm;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₱${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
