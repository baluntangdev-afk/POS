import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows the reference-number payment bottom sheet (card / e-wallet / bank).
/// Returns the entered reference number, or null if the user cancelled.
Future<String?> showReferencePaymentSheet(
  BuildContext context, {
  required String methodLabel,
  required double totalDue,
  String? initialReference,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) => _ReferencePaymentSheet(
      methodLabel: methodLabel,
      totalDue: totalDue,
      initialReference: initialReference,
    ),
  );
}

class _ReferencePaymentSheet extends HookWidget {
  const _ReferencePaymentSheet({
    required this.methodLabel,
    required this.totalDue,
    this.initialReference,
  });

  final String methodLabel;
  final double totalDue;
  final String? initialReference;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final controller = useTextEditingController(text: initialReference ?? '');

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
                  '$methodLabel Payment',
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
                  'REFERENCE / TRANSACTION NO.',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: AppTextStyles.bodyLg,
                  decoration: InputDecoration(
                    hintText: 'e.g. TXN-12345678',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a reference number';
                    }
                    return null;
                  },
                ),
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
                          Navigator.of(context).pop(controller.text.trim());
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
