import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/uuidv7.dart';
import '../../../widgets/button.dart';
import '../entities/line_item.dart';
import '../entities/modifier_group.dart';
import '../entities/modifier_option.dart';
import '../entities/product.dart';
import '../entities/product_variant.dart';
import '../entities/selected_modifier.dart';
import '../entities/selected_option.dart';
import '../entities/selected_variant.dart';
import '../state/line_item_notifier.dart';

Future<LineItem?> showLineItemDialog(
  BuildContext context, {
  required int productId,
  int initialQuantity = 1,
  SelectedVariant? initialVariant,
  IList<SelectedModifier> initialModifiers = const IList.empty(),
}) {
  return showDialog<LineItem>(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          switch (ref.watch(lineItemProvider(productId))) {
            case AsyncLoading():
              return const Center(child: CircularProgressIndicator());
            case AsyncError():
              return const Center(child: Text('Cannot load product'));
            case AsyncData(value: final product):
              final defaultVariant =
                  product.variants.isEmpty
                      ? null
                      : product.variants.firstWhere(
                        (variant) => variant.isDefault,
                        orElse: () => product.variants.first,
                      );
              if (defaultVariant != null) {
                final ProductVariant(:id, :name, :price) = defaultVariant;
                initialVariant ??= SelectedVariant(id: id, name: name, price: price);
              }
              return LineItemDialog(
                product: product,
                initialQuantity: initialQuantity,
                initialVariant: initialVariant,
                initialModifiers: initialModifiers,
              );
          }
        },
      );
    },
  );
}

class LineItemDialog extends HookConsumerWidget {
  const LineItemDialog({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.initialVariant,
    this.initialModifiers = const IList.empty(),
  });

  final Product product;
  final int initialQuantity;
  final SelectedVariant? initialVariant;
  final IList<SelectedModifier> initialModifiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQuantity = useState(initialQuantity);
    final selectedVariant = useState(initialVariant);
    final selectedModifiers = useState<IList<SelectedModifier>>(initialModifiers);

    void onQuantityChanged(int? value) {
      if (value == null || value < 1) return;
      selectedQuantity.value = value;
    }

    Decimal calculateCurrentPrice() {
      final basePrice = selectedVariant.value?.price ?? product.price;
      final modifiersPrice = selectedModifiers.value.fold(
        Decimal.zero,
        (total, modifier) => total + modifier.price,
      );
      final quantity = Decimal.fromInt(selectedQuantity.value);
      return (basePrice + modifiersPrice) * quantity;
    }

    final modifierGroups =
        selectedVariant.value != null
            ? product.variants
                .firstWhere((variant) => variant.id == selectedVariant.value!.id)
                .modifierGroups
            : const IList<ModifierGroup>.empty();
    final currentPrice = calculateCurrentPrice();

    void toggleModifierOption(ModifierOption option) {
      final modifierGroup = modifierGroups.firstWhere((group) => group.options.contains(option));

      final existingModifierIndex = selectedModifiers.value.indexWhere(
        (modifier) => modifier.id == modifierGroup.id,
      );

      if (existingModifierIndex != -1) {
        final existingModifier = selectedModifiers.value[existingModifierIndex];
        final optionExists = existingModifier.options.any((opt) => opt.id == option.id);

        if (optionExists) {
          // Check if removing this option would violate minSelections
          if (modifierGroup.minSelections > 0 &&
              existingModifier.options.length <= modifierGroup.minSelections) {
            return; // Cannot remove: would violate minSelections
          }

          // Remove the option
          final updatedOptions =
              existingModifier.options.where((opt) => opt.id != option.id).toIList();
          if (updatedOptions.isEmpty) {
            // Remove the entire modifier if no options remain
            selectedModifiers.value = selectedModifiers.value.remove(existingModifier);
          } else {
            // Update with remaining options
            final updatedModifier = SelectedModifier(
              id: existingModifier.id,
              name: existingModifier.name,
              options: updatedOptions,
            );
            selectedModifiers.value = selectedModifiers.value
                .remove(existingModifier)
                .add(updatedModifier);
          }
        } else {
          // Add the option
          // Radio button behavior: replace all options when maxSelections is 1
          if (modifierGroup.maxSelections == 1) {
            final updatedModifier = SelectedModifier(
              id: existingModifier.id,
              name: existingModifier.name,
              options: IList([
                SelectedOption(id: option.id, name: option.name, price: option.price),
              ]),
            );
            selectedModifiers.value = selectedModifiers.value
                .remove(existingModifier)
                .add(updatedModifier);
          } else {
            // Checkbox behavior: check maxSelections before adding
            if (modifierGroup.maxSelections > 0 &&
                existingModifier.options.length >= modifierGroup.maxSelections) {
              return; // Cannot add: would violate maxSelections
            }
            // Checkbox behavior: add to existing options
            final updatedModifier = SelectedModifier(
              id: existingModifier.id,
              name: existingModifier.name,
              options: existingModifier.options.add(
                SelectedOption(id: option.id, name: option.name, price: option.price),
              ),
            );
            selectedModifiers.value = selectedModifiers.value
                .remove(existingModifier)
                .add(updatedModifier);
          }
        }
      } else {
        // No existing modifier for this group: create new one
        if (modifierGroup.maxSelections == 0) {
          return; // Cannot add: maxSelections is 0
        }
        final newModifier = SelectedModifier(
          id: modifierGroup.id,
          name: modifierGroup.name,
          options: IList([SelectedOption(id: option.id, name: option.name, price: option.price)]),
        );
        selectedModifiers.value = selectedModifiers.value.add(newModifier);
      }
    }

    bool areModifierSelectionsValid() {
      for (final group in modifierGroups) {
        final modifier = selectedModifiers.value.firstWhere(
          (m) => m.id == group.id,
          orElse: () => const SelectedModifier(id: -1, name: '', options: IList.empty()),
        );
        final currentGroupSelections = modifier.options.length;

        if (group.minSelections > 0 && currentGroupSelections < group.minSelections) {
          return false;
        }

        if (group.maxSelections > 0 && currentGroupSelections > group.maxSelections) {
          return false;
        }
      }
      return true;
    }

    IList<ModifierOption> getSelectedModifierOptions() {
      final allOptions = <ModifierOption>[];

      for (final selectedModifier in selectedModifiers.value) {
        // Find the modifier group to get the actual ModifierOption objects
        final group = modifierGroups.firstWhere(
          (g) => g.id == selectedModifier.id,
          orElse:
              () => const ModifierGroup(
                id: -1,
                name: '',
                minSelections: 0,
                maxSelections: 0,
                options: IList.empty(),
              ),
        );

        for (final selectedOption in selectedModifier.options) {
          // Find the corresponding ModifierOption
          final modifierOption = group.options.firstWhere(
            (opt) => opt.id == selectedOption.id,
            orElse: () => ModifierOption(id: -1, name: '', price: Decimal.zero),
          );
          allOptions.add(modifierOption);
        }
      }

      return allOptions.toIList();
    }

    LineItem buildLineItem() {
      return LineItem(
        id: UuidV7.generate(),
        productId: product.id,
        productName: product.name,
        productImage: product.image,
        quantity: selectedQuantity.value,
        variant: selectedVariant.value!,
        modifiers: selectedModifiers.value,
      );
    }

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: context.responsive.value(kiosk: 1200, tablet: 600, phone: double.infinity),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              _ProductDetails(
                product: product,
                selectedQuantity: selectedQuantity.value,
                selectedVariant: selectedVariant.value,
                onIncrease: () => onQuantityChanged(selectedQuantity.value + 1),
                onDecrease: () => onQuantityChanged(selectedQuantity.value - 1),
              ),
              Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                ),
                child: _VariantSelector(
                  variants: product.variants,
                  selectedVariant:
                      selectedVariant.value != null
                          ? product.variants.firstWhere(
                            (variant) => variant.id == selectedVariant.value!.id,
                          )
                          : null,
                  onVariantSelected: (variant) {
                    selectedVariant.value = SelectedVariant(
                      id: variant.id,
                      name: variant.name,
                      price: variant.price,
                    );
                  },
                ),
              ),
              Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                ),
                child: _ModifierGroupSelector(
                  modifierGroups: modifierGroups,
                  selectedOptions: getSelectedModifierOptions(),
                  onToggleOption: toggleModifierOption,
                ),
              ),
              Gap(context.responsive.value(kiosk: 64, tablet: 48, phone: 32)),
              _ActionControls(
                totalAmount: currentPrice,
                onCancel: () => Navigator.of(context).pop(),
                onConfirm:
                    areModifierSelectionsValid()
                        ? () => Navigator.of(context).pop(buildLineItem())
                        : null,
              ),
              Gap(context.responsive.value(kiosk: 64, tablet: 48, phone: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.selectedQuantity,
    this.selectedVariant,
    required this.onIncrease,
    required this.onDecrease,
  });

  final Product product;
  final int selectedQuantity;
  final SelectedVariant? selectedVariant;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        Image.memory(
          product.image,
          width: context.responsive.value(kiosk: 200, tablet: 150, phone: 100),
          height: context.responsive.value(kiosk: 200, tablet: 150, phone: 100),
          fit: BoxFit.contain,
        ),
        Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 36, tablet: 24, phone: 18),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                  color: ColorSet.text.withValues(alpha: 0.5),
                ),
              ),
              Gap(context.responsive.value(kiosk: 4, tablet: 4, phone: 4)),
              _QuantityControls(
                quantity: selectedQuantity,
                onIncrease: onIncrease,
                onDecrease: onDecrease,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Text(
                'Base Price',
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                  color: ColorSet.text.withValues(alpha: 0.5),
                ),
              ),
              Text(
                (selectedVariant?.price ?? product.price).pesoFormatted,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 30, tablet: 20, phone: 16),
                  color: ColorSet.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            height: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
            width: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
            decoration: BoxDecoration(
              color: ColorSet.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              color: ColorSet.secondary,
              size: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
            ),
          ),
        ),
        Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
        Text(
          '$quantity',
          style: TextStyle(fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12)),
        ),
        Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            height: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
            width: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
            decoration: const BoxDecoration(color: ColorSet.secondary, shape: BoxShape.circle),
            child: Icon(
              Icons.add,
              color: ColorSet.light,
              size: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  final IList<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      runSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      children:
          variants.map((variant) {
            final isSelected = variant == selectedVariant;
            return GestureDetector(
              onTap: () => onVariantSelected(variant),
              child: Container(
                width: context.responsive.value(kiosk: 120, tablet: 90, phone: 70),
                padding: EdgeInsets.all(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                decoration: BoxDecoration(
                  color: isSelected ? ColorSet.primary.withValues(alpha: 0.2) : ColorSet.light,
                  border: Border.all(
                    color: isSelected ? ColorSet.primary : ColorSet.text.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variant.name,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (variant.price != Decimal.zero) ...[
                      const Gap(4),
                      Text(
                        variant.price.pesoFormatted,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 16, tablet: 12, phone: 12),
                          color: ColorSet.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _ModifierGroupSelector extends StatelessWidget {
  const _ModifierGroupSelector({
    required this.modifierGroups,
    required this.selectedOptions,
    required this.onToggleOption,
  });

  final IList<ModifierGroup> modifierGroups;
  final IList<ModifierOption> selectedOptions;
  final ValueChanged<ModifierOption> onToggleOption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          modifierGroups.map((group) {
            return _ModifierGroupSection(
              group: group,
              selectedOptions: selectedOptions,
              onToggleOption: onToggleOption,
            );
          }).toList(),
    );
  }
}

class _ModifierGroupSection extends StatelessWidget {
  const _ModifierGroupSection({
    required this.group,
    required this.selectedOptions,
    required this.onToggleOption,
  });

  final ModifierGroup group;
  final IList<ModifierOption> selectedOptions;
  final ValueChanged<ModifierOption> onToggleOption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.name,
          style: TextStyle(
            fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (group.minSelections > 0 || group.maxSelections > 0) ...[
          const Gap(4),
          Text(
            _getSelectionLabel(group),
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 16, tablet: 12, phone: 10),
              color: ColorSet.text.withValues(alpha: 0.6),
            ),
          ),
        ],
        Gap(context.responsive.value(kiosk: 12, tablet: 8, phone: 8)),
        Wrap(
          spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          runSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          children:
              group.options.map((option) {
                final isSelected = selectedOptions.contains(option);
                return _ModifierOptionCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => onToggleOption(option),
                );
              }).toList(),
        ),
        Gap(context.responsive.value(kiosk: 24, tablet: 16, phone: 16)),
      ],
    );
  }

  String _getSelectionLabel(ModifierGroup group) {
    if (group.minSelections == group.maxSelections) {
      return 'Select ${group.minSelections}';
    } else if (group.minSelections > 0 && group.maxSelections > 0) {
      return 'Select ${group.minSelections}-${group.maxSelections}';
    } else if (group.minSelections > 0) {
      return 'Select at least ${group.minSelections}';
    } else if (group.maxSelections > 0) {
      return 'Select up to ${group.maxSelections}';
    }
    return '';
  }
}

class _ModifierOptionCard extends StatelessWidget {
  const _ModifierOptionCard({required this.option, required this.isSelected, required this.onTap});

  final ModifierOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.responsive.value(kiosk: 160, tablet: 120, phone: 96),
        height: context.responsive.value(kiosk: 80, tablet: 60, phone: 60),
        decoration: BoxDecoration(
          color: isSelected ? ColorSet.secondary.withValues(alpha: 0.1) : ColorSet.light,
          border: Border.all(
            color: isSelected ? ColorSet.secondary : ColorSet.text.withValues(alpha: 0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(
            context.responsive.value(kiosk: 12, tablet: 8, phone: 8),
          ),
        ),
        padding: EdgeInsets.all(context.responsive.value(kiosk: 12, tablet: 8, phone: 8)),
        child: Row(
          children: [
            if (option.image != null) ...[
              Image.memory(
                option.image!,
                width: context.responsive.value(kiosk: 40, tablet: 32, phone: 24),
                height: context.responsive.value(kiosk: 40, tablet: 32, phone: 24),
                fit: BoxFit.cover,
              ),
              Gap(context.responsive.value(kiosk: 8, tablet: 4, phone: 4)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 16, tablet: 12, phone: 12),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (option.price != Decimal.zero) ...[
                    const Gap(4),
                    Text(
                      option.price.pesoFormatted,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 14, tablet: 12, phone: 12),
                        color: ColorSet.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorSet.secondary,
                size: context.responsive.value(kiosk: 20, tablet: 15, phone: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionControls extends StatelessWidget {
  const _ActionControls({required this.totalAmount, required this.onCancel, this.onConfirm});

  final Decimal totalAmount;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
            Text(
              'Total',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 14),
              ),
            ),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            const Spacer(),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            Text(
              totalAmount.pesoFormatted,
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 30, tablet: 24, phone: 18),
                color: ColorSet.secondary,
              ),
            ),
            Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
          ],
        ),
        Gap(context.responsive.value(kiosk: 64, tablet: 48, phone: 32)),
        Row(
          children: [
            Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
            Button.outlined(
              foregroundColor: ColorSet.text,
              onPressed: onCancel,
              label: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                  vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                  ),
                ),
              ),
            ),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            const Spacer(),
            Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
            Button(
              onPressed: onConfirm,
              foregroundColor: ColorSet.light,
              backgroundColor: ColorSet.secondary,
              label: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                  vertical: context.responsive.value(kiosk: 8, tablet: 6, phone: 4),
                ),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                  ),
                ),
              ),
            ),
            Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
          ],
        ),
      ],
    );
  }
}
