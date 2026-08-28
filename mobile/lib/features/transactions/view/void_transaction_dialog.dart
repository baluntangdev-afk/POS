import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/popup_menu_form_field.dart';
import '../../auth/entities/user_entity.dart';
import '../../auth/state/auth_providers.dart';
import '../../cashier_accounting/daily_report/state/daily_report_notifier.dart';
import '../../cashier_accounting/x_reading/state/x_reading_notifier.dart';
import '../../cashier_accounting/z_reading/state/z_reading_notifier.dart';
import '../../ordering/state/receipt_notifier.dart';
import '../../ordering/use_cases/void_sale.dart';
import '../state/transactions_notifier.dart';

class VoidTransactionDialog extends HookConsumerWidget {
  const VoidTransactionDialog({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  final int saleId;
  final String invoiceNumber;
  final double totalAmount;

  static Future<bool> show(
    BuildContext context, {
    required int saleId,
    required String invoiceNumber,
    required double totalAmount,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => VoidTransactionDialog(
            saleId: saleId,
            invoiceNumber: invoiceNumber,
            totalAmount: totalAmount,
          ),
        ) ??
        false;
  }

  static const _maxPinLength = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reasonCtrl = useTextEditingController();
    final pinCtrl = useTextEditingController();
    final selectedAuthorizer = useState<UserEntity?>(null);
    final isLoading = useState(false);
    final error = useState<String?>(null);
    final authorizersAsync = ref.watch(authorizersProvider);

    Future<void> confirmVoid() async {
      if (isLoading.value) return;

      final reason = reasonCtrl.text.trim();
      final authorizer = selectedAuthorizer.value;
      final pin = pinCtrl.text.trim();

      final missing = <String>[];
      if (reason.isEmpty) missing.add('void reason');
      if (authorizer == null) missing.add('authorizer');
      if (pin.length < 4) missing.add('PIN (min. 4 digits)');

      if (missing.isNotEmpty) {
        error.value = 'Please provide: ${missing.join(', ')}.';
        return;
      }

      isLoading.value = true;
      error.value = null;

      final authorized = await ref
          .read(authNotifierProvider.notifier)
          .verifyPinForUser(authorizer!.id, pin);

      if (!authorized) {
        isLoading.value = false;
        pinCtrl.clear();
        error.value = 'Invalid PIN or insufficient permissions';
        return;
      }

      await ref.read(voidSaleProvider)(saleId: saleId, reason: reason);

      // A void changes the same figures a sale/refund does, so refresh every
      // view that reads them — otherwise the transactions list (and readings)
      // keep showing the pre-void status until reopened.
      ref.invalidate(transactionsProvider);
      ref.invalidate(receiptProvider(saleId));
      ref.invalidate(xReadingProvider);
      ref.invalidate(zReadingProvider);
      ref.invalidate(dailyReportProvider);

      isLoading.value = false;
      if (context.mounted) Navigator.of(context).pop(true);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      boxShadow: AppShadows.card,
                    ),
                    child: const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Void Transaction',
                            style: AppTextStyles.headingSm.copyWith(color: AppColors.error)),
                        Text(
                          '$invoiceNumber  ·  ₱${totalAmount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'This action cannot be undone. The transaction will be permanently cancelled.',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('REASON FOR VOID',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Enter void reason...'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('SUPERVISOR AUTHORIZATION',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    authorizersAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Failed to load authorizers: $e',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                      data: (authorizers) => PopupMenuFormField<UserEntity>(
                        initialValue: selectedAuthorizer.value,
                        decoration: const InputDecoration(labelText: 'Authorizer'),
                        items: authorizers
                            .map((u) =>
                                PopupMenuFormFieldItem(value: u, child: Text('${u.name} (${u.role})')))
                            .toList(),
                        onChanged: (u) => selectedAuthorizer.value = u,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('SUPERVISOR PIN',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: _maxPinLength,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: 'Enter PIN',
                        counterText: '',
                      ),
                      onSubmitted: (_) => confirmVoid(),
                    ),
                    if (error.value != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(error.value!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading.value ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isLoading.value ? null : confirmVoid,
                      icon: isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.block_rounded, size: 16),
                      label: Text(isLoading.value ? 'Voiding...' : 'Void Transaction'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
