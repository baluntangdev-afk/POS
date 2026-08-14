import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
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
  required AppDatabase db,
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
      db: db,
    ),
  );
}

class _ModifierSheet extends HookConsumerWidget {
  final OrderProduct product;
  final String groupName;
  final AppDatabase db;

  const _ModifierSheet({
    required this.product,
    required this.groupName,
    required this.db,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = useState(1);
    final notesController = useTextEditingController();
    final selectedByGroup = useState<Map<int, Set<int>>>({});
    final groupData = useState<List<_ModifierGroupData>>([]);
    final variants = useState<List<ProductVariantsTableData>>([]);
    final selectedVariant = useState<ProductVariantsTableData?>(null);
    final isLoading = useState(true);

    useEffect(() {
      Future(() async {
        final allVariants = await db.productsDao.getVariantsForProduct(product.id);
        final activeVariants = allVariants.where((v) => v.isActive).toList();

        final groups = await db.productsDao.getModifierGroupsForProduct(product.id);
        final result = <_ModifierGroupData>[];
        for (final g in groups) {
          final options = await db.productsDao.getOptionsForGroup(g.id);
          result.add(_ModifierGroupData(group: g, options: options));
        }
        if (context.mounted) {
          variants.value = activeVariants;
          if (activeVariants.isNotEmpty) {
            selectedVariant.value = activeVariants.firstWhere(
              (v) => v.isDefault,
              orElse: () => activeVariants.first,
            );
          }
          groupData.value = result;
          isLoading.value = false;
        }
      });
      return null;
    }, const []);

    void toggleOption(int groupId, int optionId, int maxSelections) {
      final current = Map<int, Set<int>>.from(selectedByGroup.value);
      final groupSet = Set<int>.from(current[groupId] ?? {});
      if (groupSet.contains(optionId)) {
        groupSet.remove(optionId);
      } else {
        if (maxSelections == 1) {
          groupSet.clear();
        } else if (groupSet.length >= maxSelections) {
          return;
        }
        groupSet.add(optionId);
      }
      current[groupId] = groupSet;
      selectedByGroup.value = current;
    }

    bool canConfirm() {
      if (variants.value.isNotEmpty && selectedVariant.value == null) return false;
      for (final g in groupData.value) {
        if (g.group.isRequired) {
          final sel = selectedByGroup.value[g.group.id] ?? {};
          if (sel.isEmpty) return false;
        }
      }
      return true;
    }

    void confirm() {
      final modifiers = <SelectedModifierGroup>[];
      for (final g in groupData.value) {
        final selectedIds = selectedByGroup.value[g.group.id] ?? {};
        if (selectedIds.isEmpty) continue;
        final selectedOpts = g.options
            .where((o) => selectedIds.contains(o.id))
            .map((o) => SelectedModifierOption(
                  optionId: o.id,
                  name: o.name,
                  additionalPrice: o.additionalPrice,
                ))
            .toList();
        modifiers.add(SelectedModifierGroup(
          groupId: g.group.id,
          groupName: g.group.name,
          selected: selectedOpts,
        ));
      }

      final lineItem = LineItem(
        id: '${product.id}_${DateTime.now().microsecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        groupName: groupName,
        imageUrl: product.imageUrl,
        basePrice: selectedVariant.value?.price ?? product.price,
        quantity: quantity.value,
        modifiers: modifiers,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        variantName: selectedVariant.value?.name ?? '',
      );

      Navigator.of(context).pop(lineItem);
    }

    final totalPrice = (selectedVariant.value?.price ?? product.price) +
        groupData.value
            .expand((g) => g.options.where((o) =>
                (selectedByGroup.value[g.group.id] ?? {}).contains(o.id)))
            .fold(0.0, (s, o) => s + o.additionalPrice);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize:
          groupData.value.isEmpty && variants.value.isEmpty ? 0.45 : 0.7,
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
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    children: [
                      // Variants
                      if (variants.value.isNotEmpty) ...[
                        _VariantSection(
                          variants: variants.value,
                          selectedId: selectedVariant.value?.id,
                          onSelect: (v) => selectedVariant.value = v,
                        ),
                        const Gap(AppSpacing.md),
                      ],

                      // Modifier groups
                      ...groupData.value.map((g) => _ModifierGroupSection(
                            data: g,
                            selectedIds: selectedByGroup.value[g.group.id] ?? {},
                            onToggle: (optionId) => toggleOption(
                                g.group.id, optionId, g.group.maxSelections),
                          )),

                      if (groupData.value.isNotEmpty) const Gap(AppSpacing.md),

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
  final List<ProductVariantsTableData> variants;
  final int? selectedId;
  final ValueChanged<ProductVariantsTableData> onSelect;

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
                priceLabel: 'PHP ${v.price.toStringAsFixed(2)}',
                isSelected: v.id == selectedId,
                onTap: () => onSelect(v),
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
  final VoidCallback onTap;

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

class _ModifierGroupSection extends StatelessWidget {
  final _ModifierGroupData data;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const _ModifierGroupSection({
    required this.data,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isSingleSelect = data.group.maxSelections == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _SectionLabel(data.group.name),
              ),
              const Gap(AppSpacing.sm),
              if (data.group.isRequired)
                const _RequiredBadge()
              else
                Text(
                  'Optional · max ${data.group.maxSelections}',
                  style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary),
                ),
            ],
          ),
          const Gap(AppSpacing.sm),
          if (isSingleSelect)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: data.options.map((opt) {
                return _PillChip(
                  label: opt.name,
                  priceLabel: opt.additionalPrice > 0
                      ? '+PHP ${opt.additionalPrice.toStringAsFixed(2)}'
                      : null,
                  isSelected: selectedIds.contains(opt.id),
                  onTap: () => onToggle(opt.id),
                );
              }).toList(),
            )
          else
            ...data.options.map((opt) {
              final isSelected = selectedIds.contains(opt.id);
              return GestureDetector(
                onTap: () => onToggle(opt.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: Text(opt.name, style: AppTextStyles.bodyMd),
                      ),
                      if (opt.additionalPrice > 0)
                        Text(
                          '+PHP ${opt.additionalPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
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

class _ModifierGroupData {
  final ModifierGroupsTableData group;
  final List<ModifierOptionsTableData> options;

  const _ModifierGroupData({required this.group, required this.options});
}
