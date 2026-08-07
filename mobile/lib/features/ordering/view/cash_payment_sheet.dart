import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_filled_button.dart';

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

    // Whether the field currently holds a value built from quick-amount
    // taps (or is fresh) — the next keypad digit should replace it rather
    // than append, since appending onto e.g. "120.00" would be nonsensical.
    final replaceOnNextDigit = useState(true);

    void setAmount(double amount) {
      final text = amount.toStringAsFixed(2);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      replaceOnNextDigit.value = true;
    }

    void addQuickAmount(double amount) {
      setAmount(cashReceived + amount);
    }

    void appendDigit(String digit) {
      final current = controller.text;
      if (replaceOnNextDigit.value) {
        replaceOnNextDigit.value = false;
        final next = digit == '.' ? '0.' : digit;
        controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        return;
      }
      if (digit == '.' && current.contains('.')) return;
      final next = current + digit;
      controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }

    void backspace() {
      final current = controller.text;
      if (current.isEmpty) return;
      replaceOnNextDigit.value = false;
      final next = current.substring(0, current.length - 1);
      controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
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
                    boxShadow: AppShadows.card,
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
                _QuickAmountChip(
                  label: 'Exact',
                  amount: totalDue,
                  isSelected: cashReceived == totalDue,
                  onTap: () => setAmount(totalDue),
                ),
                const Gap(AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 2.1,
                  children: [
                    for (final amount in _quickAmountValues)
                      _QuickAmountGridButton(
                        amount: amount,
                        onTap: () => addQuickAmount(amount),
                      ),
                  ],
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: controller,
                  readOnly: true,
                  showCursor: true,
                  textAlign: TextAlign.center,
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
                _Keypad(onDigit: appendDigit, onBackspace: backspace),
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
                        Flexible(
                          child: Text(
                            'PHP ${change.toStringAsFixed(2)}',
                            style: AppTextStyles.priceLg.copyWith(color: AppColors.success),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      child: GradientFilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.of(context).pop(cashReceived);
                        },
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

/// Static cash denominations offered as one-tap add-ons — tapping a value
/// adds it to whatever is currently in the cash received field (e.g.
/// tapping 20 then 100 results in 120), modeling handing over multiple bills.
const _quickAmountValues = [20.0, 50.0, 100.0, 200.0, 500.0, 1000.0];

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.label,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 72, minHeight: AppSpacing.touchMin - 8),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLg.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Grid cell for a static quick-amount denomination — tapping adds the
/// amount to the current cash received total.
class _QuickAmountGridButton extends StatelessWidget {
  final double amount;
  final VoidCallback onTap;

  const _QuickAmountGridButton({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            'PHP ${amount.toStringAsFixed(0)}',
            style: AppTextStyles.labelLg.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// On-screen numeric keypad for cash entry — avoids relying on the OS
/// keyboard, matching the kiosk's touch-first input pattern.
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _Keypad({required this.onDigit, required this.onBackspace});

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.1,
      children: _keys.map((k) {
        final isBackspace = k == '⌫';
        return Material(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: isBackspace ? onBackspace : () => onDigit(k),
            child: Center(
              child: isBackspace
                  ? const Icon(
                      Icons.backspace_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    )
                  : Text(k, style: AppTextStyles.headingSm),
            ),
          ),
        );
      }).toList(),
    );
  }
}
