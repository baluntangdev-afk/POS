import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../features/settings/state/store_info_notifier.dart';
import '../features/settings/view/payment_method_form_dialog.dart';

class PaymentMethodsCard extends ConsumerWidget {
  const PaymentMethodsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PAYMENT METHODS',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const PaymentMethodFormDialog(),
                ),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                tooltip: 'Add Payment Method',
              ),
            ],
          ),
          methodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e', style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
            data: (methods) {
              if (methods.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No payment methods added yet.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
                  ),
                );
              }
              return Column(
                children: methods.map((m) {
                  final subtitleParts = [
                    if (m.accountName != null && m.accountName!.isNotEmpty) m.accountName!,
                    if (m.accountNumber != null && m.accountNumber!.isNotEmpty) m.accountNumber!,
                  ];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.label),
                    subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => PaymentMethodFormDialog(existing: m),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => _confirmDelete(context, ref, m.id, m.label),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment method?'),
        content: Text('Remove "$label"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(paymentMethodsProvider.notifier).delete(id);
    }
  }
}
