import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_filled_button.dart';
import '../entities/line_item.dart';
import '../state/ordering_notifier.dart';

Future<LineItem?> showModifierDialog(
  BuildContext context, {
  required OrderProduct product,
  required String groupName,
}) {
  return showModalBottomSheet<LineItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) => _ModifierSheet(
      product: product,
      groupName: groupName,
    ),
  );
}

class _ModifierSheet extends HookConsumerWidget {
  final OrderProduct product;
  final String groupName;

  const _ModifierSheet({required this.product, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = useState(1);
    final notesController = useTextEditingController();
    final variants = product.variants;
    final selectedVariant = useState<OrderVariant?>(
      variants.where((v) => v.isAvailable).firstOrNull,
    );

    bool canConfirm() => selectedVariant.value != null;

    void confirm() {
      final lineItem = LineItem(
        id: '${product.id}_${DateTime.now().microsecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        groupName: groupName,
        imageUrl: product.imageUrl,
        basePrice: selectedVariant.value!.price,
        quantity: quantity.value,
        modifiers: const [],
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        variantName: selectedVariant.value!.name,
      );

      Navigator.of(context).pop(lineItem);
    }

    final totalPrice = selectedVariant.value?.price ?? product.price;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: variants.length > 1 ? 0.7 : 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTextStyles.headingMd),
                      const Gap(2),
                      Text(
                        'PHP ${totalPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.priceMd.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          const Divider(height: AppSpacing.lg),

          // Scrollable content
          Expanded(
            child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    children: [
                      _VariantSection(
                        variants: variants,
                        selectedId: selectedVariant.value?.id,
                        onSelect: (v) => selectedVariant.value = v,
                      ),
                      const Gap(AppSpacing.md),

                      // Notes
                      const _SectionLabel('Notes (optional)'),
                      const Gap(AppSpacing.sm),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'e.g. no onions, extra spicy…',
                          hintStyle: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.textDisabled),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
          ),

          // Quantity + confirm
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppShadows.elevated,
              border: const Border(
                  top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _QuantityStepper(
                  quantity: quantity.value,
                  onDecrease: () {
                    if (quantity.value > 1) quantity.value--;
                  },
                  onIncrease: () => quantity.value++,
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: GradientFilledButton(
                    onPressed: canConfirm() ? confirm : null,
                    child: Text(
                      'Add to Cart · PHP ${(totalPrice * quantity.value).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gap(MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _VariantSection extends StatelessWidget {
  final List<OrderVariant> variants;
  final int? selectedId;
  final ValueChanged<OrderVariant> onSelect;

  const _VariantSection({
    required this.variants,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('Variant'),
              const Gap(AppSpacing.sm),
              const _RequiredBadge(),
            ],
          ),
          const Gap(AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: variants.map((v) {
              return _PillChip(
                label: v.name,
                priceLabel: v.isAvailable
                    ? 'PHP ${v.price.toStringAsFixed(2)}'
                    : 'Out of stock',
                isSelected: v.id == selectedId,
                onTap: v.isAvailable ? () => onSelect(v) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase caption used for section headings, matching the app's
/// existing "ORDER TYPE" / "NOTES" caption style.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        'Required',
        style: AppTextStyles.labelMd.copyWith(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

/// Compact single-select option used for variants and radio-style modifier
/// groups (maxSelections == 1) — a wrapping row of chips instead of a
/// stacked full-width list.
class _PillChip extends StatelessWidget {
  final String label;
  final String? priceLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PillChip({
    required this.label,
    this.priceLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 84),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (priceLabel != null) ...[
              const Gap(2),
              Text(
                priceLabel!,
                style: AppTextStyles.bodySm.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrease : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$quantity',
              style: AppTextStyles.headingSm,
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, filled: true, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _StepBtn({required this.icon, this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? Colors.white
              : (onTap != null ? AppColors.primary : AppColors.textDisabled),
        ),
      ),
    );
  }
}
