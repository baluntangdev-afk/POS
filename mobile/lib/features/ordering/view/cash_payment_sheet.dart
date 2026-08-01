import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows the cash payment bottom sheet. Returns the cash amount tendered,
/// or null if the user cancelled.
Future<double?> showCashPaymentSheet(
  BuildContext context, {
  required double totalDue,
  double? initialCashReceived,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) => _CashPaymentSheet(
      totalDue: totalDue,
      initialCashReceived: initialCashReceived,
    ),
  );
}

class _CashPaymentSheet extends HookWidget {
  const _CashPaymentSheet({required this.totalDue, this.initialCashReceived});

  final double totalDue;
  final double? initialCashReceived;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controller = useTextEditingController(
      text: (initialCashReceived ?? 0) > 0 ? initialCashReceived!.toStringAsFixed(2) : '',
    );
    useListenable(controller);

    final cashReceived = double.tryParse(controller.text) ?? 0.0;
    final change = (cashReceived - totalDue).clamp(0.0, double.infinity);

    void addDenomination(int amount) {
      final current = double.tryParse(controller.text) ?? 0.0;
      final text = (current + amount).toStringAsFixed(2);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  ),
                ),
                Text(
                  'Cash Payment',
                  style: AppTextStyles.headingLg,
                  textAlign: TextAlign.center,
                ),
                const Gap(AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Amount Due',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
                      ),
                      const Gap(4),
                      Text(
                        'PHP ${totalDue.toStringAsFixed(2)}',
                        style: AppTextStyles.displayMd,
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.lg),
                Text(
                  'CASH RECEIVED',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: AppTextStyles.priceLg.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixText: 'PHP ',
                    hintText: totalDue.toStringAsFixed(2),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null) return 'Enter a valid amount';
                    if (n < totalDue) {
                      return 'Must be at least PHP ${totalDue.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [20, 50, 100, 200, 500, 1000].map((d) {
                    return OutlinedButton(
                      onPressed: () => addDenomination(d),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        minimumSize: const Size(84, AppSpacing.touchMin - 8),
                      ),
                      child: Text('$d', style: AppTextStyles.headingSm),
                    );
                  }).toList(),
                ),
                if (cashReceived >= totalDue) ...[
                  const Gap(AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change',
                          style: AppTextStyles.headingSm.copyWith(color: AppColors.success),
                        ),
                        Text(
                          'PHP ${change.toStringAsFixed(2)}',
                          style: AppTextStyles.priceLg.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
                const Gap(AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppSpacing.touchMin),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.of(context).pop(cashReceived);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppSpacing.touchMin),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
