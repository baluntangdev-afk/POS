import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/transaction_summary.dart';
import '../state/transactions_notifier.dart';
import 'void_transaction_dialog.dart';

const _kLoadMoreThreshold = 200;

class TransactionsScreen extends HookConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(transactionsProvider);
    final searchCtrl = useTextEditingController();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Transactions'),
          leading: IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              tooltip: 'Filter by date',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate:
                      ref.read(transactionsProvider.notifier).date ??
                      DateTime.now(),
                );
                if (picked != null) {
                  await ref.read(transactionsProvider.notifier).setDate(picked);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search by invoice # (e.g. #000123)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted:
                    (v) => ref.read(transactionsProvider.notifier).setSearch(v),
              ),
            ),
            Expanded(
              child: pageAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (page) {
                  if (page.items.isEmpty) {
                    return const Center(child: Text('No transactions found'));
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () => ref.read(transactionsProvider.notifier).refresh(),
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - _kLoadMoreThreshold) {
                          ref.read(transactionsProvider.notifier).loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: page.items.length,
                        separatorBuilder:
                            (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final tx = page.items[i];
                          return _TransactionTile(
                            tx: tx,
                            onTap: () => context.push('/transactions/${tx.id}'),
                            onVoid: tx.isVoided
                                ? null
                                : () async {
                                    final voided = await VoidTransactionDialog.show(
                                      context,
                                      saleId: tx.id,
                                      invoiceNumber: tx.invoiceNumber,
                                      totalAmount: tx.netTotal,
                                    );
                                    if (voided) {
                                      ref.read(transactionsProvider.notifier).refresh();
                                    }
                                  },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionSummary tx;
  final VoidCallback onTap;
  final VoidCallback? onVoid;
  const _TransactionTile({required this.tx, required this.onTap, this.onVoid});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        tx.isVoided
            ? AppColors.error
            : tx.hasRefunds
            ? AppColors.warning
            : AppColors.success;
    final statusLabel =
        tx.isVoided
            ? 'Voided'
            : tx.isFullyRefunded
            ? 'Refunded'
            : tx.hasRefunds
            ? 'Partially Refunded'
            : 'Completed';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          title: Text(
            tx.invoiceNumber,
            style: AppTextStyles.headingSm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${tx.displayType} • ${tx.cashierName} • ${DateFormat('MMM d, h:mm a').format(tx.createdAt)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${tx.netTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.headingSm,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.bodySm.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
