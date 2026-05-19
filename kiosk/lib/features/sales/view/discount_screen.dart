import 'package:decimal/decimal.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/tax_calculator.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/discount.dart';
import '../state/ordering_notifier.dart';

class DiscountScreen extends HookConsumerWidget {
  const DiscountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountTypes = useMemoized(() => ['Senior/PWD', 'Promo']);
    final selectedDiscountType = useState('Senior/PWD');
    final selectedQuantities = useState<Map<String, int>>({});

    void onApplyDiscount(String? idNumber) {
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select items to discount.')));
        return;
      }

      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(selectedQuantities.value, (
          item,
          quantity,
        ) {
          return SeniorPwdDiscount(beneficiaryId: idNumber ?? '');
        });
      } else {
        ref
            .read(orderingProvider.notifier)
            .applyDiscount(selectedQuantities.value, (item, quantity) => null);
      }
      context.pop();
    }

    final isAndroid = context.breakpoint.isAndroid;
    final body = Column(
      children: [
        TopAppBar(title: 'Apply Discount'),
        Expanded(
          child: ResponsiveBuilder(
        kiosk: (context) {
          return _LandscapeLayout(
            selectedQuantities: selectedQuantities.value,
            onQuantitiesChanged: (val) => selectedQuantities.value = val,
            discountTypes: discountTypes,
            selectedDiscountType: selectedDiscountType.value,
            onDiscountTypeChanged: (val) => selectedDiscountType.value = val,
            onApplyDiscount: onApplyDiscount,
          );
        },
        tablet: (context) {
          return _LandscapeLayout(
            selectedQuantities: selectedQuantities.value,
            onQuantitiesChanged: (value) => selectedQuantities.value = value,
            discountTypes: discountTypes,
            selectedDiscountType: selectedDiscountType.value,
            onDiscountTypeChanged: (value) => selectedDiscountType.value = value,
            onApplyDiscount: onApplyDiscount,
          );
        },
        phone: (context) {
          return _PortraitLayout(
            selectedQuantities: selectedQuantities.value,
            onQuantitiesChanged: (value) => selectedQuantities.value = value,
            discountTypes: discountTypes,
            selectedDiscountType: selectedDiscountType.value,
            onDiscountTypeChanged: (value) => selectedDiscountType.value = value,
            onApplyDiscount: onApplyDiscount,
          );
        },
            ),
          ),
        ],
      );
    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.selectedQuantities,
    required this.onQuantitiesChanged,
    required this.discountTypes,
    required this.selectedDiscountType,
    required this.onDiscountTypeChanged,
    required this.onApplyDiscount,
  });

  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onQuantitiesChanged;
  final List<String> discountTypes;
  final String selectedDiscountType;
  final ValueChanged<String> onDiscountTypeChanged;
  final ValueChanged<String?> onApplyDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _LineItemSelectionView(
            selectedQuantities: selectedQuantities,
            onQuantitiesChanged: onQuantitiesChanged,
          ),
        ),
        Expanded(
          flex: 2,
          child: _DiscountControlsView(
            discountTypes: discountTypes,
            selectedDiscountType: selectedDiscountType,
            onDiscountTypeChanged: onDiscountTypeChanged,
            selectedQuantities: selectedQuantities,
            onApplyDiscount: onApplyDiscount,
          ),
        ),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.selectedQuantities,
    required this.onQuantitiesChanged,
    required this.discountTypes,
    required this.selectedDiscountType,
    required this.onDiscountTypeChanged,
    required this.onApplyDiscount,
  });

  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onQuantitiesChanged;
  final List<String> discountTypes;
  final String selectedDiscountType;
  final ValueChanged<String> onDiscountTypeChanged;
  final ValueChanged<String?> onApplyDiscount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _LineItemSelectionView(
            selectedQuantities: selectedQuantities,
            onQuantitiesChanged: onQuantitiesChanged,
          ),
        ),
        Expanded(
          child: _DiscountControlsView(
            discountTypes: discountTypes,
            selectedDiscountType: selectedDiscountType,
            onDiscountTypeChanged: onDiscountTypeChanged,
            selectedQuantities: selectedQuantities,
            onApplyDiscount: onApplyDiscount,
          ),
        ),
      ],
    );
  }
}

class _LineItemSelectionView extends ConsumerWidget {
  const _LineItemSelectionView({
    required this.selectedQuantities,
    required this.onQuantitiesChanged,
  });

  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onQuantitiesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItems = ref.watch(
      orderingProvider.select(
        (it) =>
            it.value?.sale.items.where((e) => e.discount == null).toIList() ?? const IList.empty(),
      ),
    );
    return Container(
      margin: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Items',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedQuantities.length == lineItems.length) {
                      onQuantitiesChanged({});
                    } else {
                      onQuantitiesChanged({for (final item in lineItems) item.id: item.quantity});
                    }
                  },
                  child: Text(
                    selectedQuantities.length == lineItems.length ? 'Deselect All' : 'Select All',
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 20, tablet: 16, phone: 14),
                      color: ColorSet.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: lineItems.length,
              separatorBuilder:
                  (context, index) => Divider(
                    height: context.responsive.value(kiosk: 30, tablet: 20, phone: 16),
                    thickness: 0.5,
                  ),
              itemBuilder: (context, index) {
                final item = lineItems[index];
                final selectedQty = selectedQuantities[item.id];
                final isSelected = selectedQty != null;
                return InkWell(
                  onTap: () {
                    if (isSelected) {
                      final newMap = Map<String, int>.from(selectedQuantities);
                      newMap.remove(item.id);
                      onQuantitiesChanged(newMap);
                    } else {
                      final newMap = Map<String, int>.from(selectedQuantities);
                      newMap[item.id] = item.quantity;
                      onQuantitiesChanged(newMap);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                      horizontal: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            if (value ?? false) {
                              final newMap = Map<String, int>.from(selectedQuantities);
                              newMap[item.id] = item.quantity;
                              onQuantitiesChanged(newMap);
                            } else {
                              final newMap = Map<String, int>.from(selectedQuantities);
                              newMap.remove(item.id);
                              onQuantitiesChanged(newMap);
                            }
                          },
                        ),
                        Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                        Container(
                          width: context.responsive.value(kiosk: 90, tablet: 72, phone: 56),
                          height: context.responsive.value(kiosk: 90, tablet: 72, phone: 56),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorSet.background,
                            image: DecorationImage(
                              image: MemoryImage(item.productImage),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 30,
                                    tablet: 20,
                                    phone: 14,
                                  ),
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (isSelected && item.quantity > 1) ...[
                                const Gap(8),
                                Row(
                                  children: [
                                    _QuantityButton(
                                      icon: Icons.remove,
                                      foregroundColor: ColorSet.secondary,
                                      backgroundColor: ColorSet.secondary.withValues(alpha: 0.2),
                                      onTap: () {
                                        if (selectedQty > 1) {
                                          final newMap = Map<String, int>.from(selectedQuantities);
                                          newMap[item.id] = selectedQty - 1;
                                          onQuantitiesChanged(newMap);
                                        }
                                      },
                                    ),
                                    Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
                                    Text(
                                      '$selectedQty',
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 20,
                                          tablet: 16,
                                          phone: 12,
                                        ),
                                      ),
                                    ),
                                    Gap(context.responsive.value(kiosk: 24, tablet: 18, phone: 12)),
                                    _QuantityButton(
                                      icon: Icons.add,
                                      foregroundColor: ColorSet.light,
                                      backgroundColor: ColorSet.secondary,
                                      onTap: () {
                                        if (selectedQty < item.quantity) {
                                          final newMap = Map<String, int>.from(selectedQuantities);
                                          newMap[item.id] = selectedQty + 1;
                                          onQuantitiesChanged(newMap);
                                        }
                                      },
                                    ),
                                    Gap(context.responsive.value(kiosk: 8, phone: 4)),
                                    Text(
                                      'of ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: context.responsive.value(
                                          kiosk: 18,
                                          tablet: 16,
                                          phone: 12,
                                        ),
                                        fontWeight: FontWeight.normal,
                                        color: ColorSet.text.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: ColorSet.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              if (item.modifiers.isNotEmpty) ...[
                                const Gap(4),
                                Text(
                                  'Add-ons: ${item.modifiers.expand((modifier) => modifier.options).map((option) => option.name).join(', ')}',
                                  style: TextStyle(
                                    fontSize: context.responsive.value(
                                      kiosk: 20,
                                      tablet: 16,
                                      phone: 12,
                                    ),
                                    fontWeight: FontWeight.normal,
                                    color: ColorSet.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                              Text(
                                item.grossAmount.pesoFormatted,
                                style: TextStyle(
                                  fontSize: context.responsive.value(
                                    kiosk: 36,
                                    tablet: 24,
                                    phone: 16,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: ColorSet.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
        width: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: foregroundColor,
          size: context.responsive.value(kiosk: 24, tablet: 18, phone: 16),
        ),
      ),
    );
  }
}

class _DiscountControlsView extends HookWidget {
  const _DiscountControlsView({
    required this.discountTypes,
    required this.selectedDiscountType,
    required this.onDiscountTypeChanged,
    required this.selectedQuantities,
    required this.onApplyDiscount,
  });

  final List<String> discountTypes;
  final String selectedDiscountType;
  final ValueChanged<String> onDiscountTypeChanged;
  final Map<String, int> selectedQuantities;
  final ValueChanged<String?> onApplyDiscount;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final idNumberController = useTextEditingController();

    void validateAndSubmit() {
      if (formKey.currentState?.validate() ?? false) {
        onApplyDiscount(idNumberController.text);
      }
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.responsive.value(kiosk: 0, tablet: 0, phone: 12),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 0),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 12),
        context.responsive.value(kiosk: 24, tablet: 16, phone: 12),
      ),
      padding: EdgeInsets.all(context.responsive.value(kiosk: 24, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Discount Type',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            discountTypes.map((type) {
                              final isSelected = selectedDiscountType == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    onDiscountTypeChanged(type);
                                  }
                                },
                                selectedColor: ColorSet.secondary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? ColorSet.secondary : ColorSet.dark,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: context.responsive.value(
                                    kiosk: 20,
                                    tablet: 16,
                                    phone: 14,
                                  ),
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? ColorSet.secondary
                                          : ColorSet.dark.withValues(alpha: 0.2),
                                ),
                              );
                            }).toList(),
                      ),
                      Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                      if (selectedDiscountType == 'Senior/PWD')
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'ID Number',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                          ),
                        ),
                      if (selectedDiscountType == 'Promo')
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'Promo Code',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
                          ),
                        ),
                      const Spacer(),
                      _SummarySection(
                        selectedQuantities: selectedQuantities,
                        selectedDiscountType: selectedDiscountType,
                      ),
                      Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                      _ConfirmButton(onTap: validateAndSubmit),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.selectedQuantities, required this.selectedDiscountType});

  final Map<String, int> selectedQuantities;
  final String selectedDiscountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItems = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );

    final grossAmount = selectedQuantities.entries.fold(Decimal.zero, (sum, entry) {
      final lineItemId = entry.key;
      final item = lineItems.firstWhere(
        (item) => item.id == lineItemId,
        orElse: () => throw Exception('Line item with ID $lineItemId not found'),
      );

      final quantity = Decimal.fromInt(entry.value);
      final basePrice = item.variant.price;
      final modifiersPrice = item.modifiers.fold(
        Decimal.zero,
        (total, modifier) => total + modifier.price,
      );

      return sum + (quantity * (basePrice + modifiersPrice));
    });

    var vatExempt = Decimal.zero;
    var discountAmount = Decimal.zero;

    if (selectedDiscountType == 'Senior/PWD') {
      const discount = SeniorPwdDiscount(beneficiaryId: 'for_calculator_use_only');
      vatExempt = grossAmount.vatAmount;
      discountAmount = discount.calculateAmount(grossAmount);
    }

    return Column(
      children: [
        _SummaryRow(label: 'Selected Items Total', amount: grossAmount),
        if (vatExempt > Decimal.zero)
          _SummaryRow(label: 'VAT Exempt', amount: -vatExempt, isDeduction: true),
        if (discountAmount > Decimal.zero)
          _SummaryRow(label: 'Discount', amount: -discountAmount, isDeduction: true),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.amount, this.isDeduction = false});

  final String label;
  final Decimal amount;
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 22, tablet: 18, phone: 14),
              color: isDeduction ? ColorSet.secondary : ColorSet.dark,
            ),
          ),
          Text(
            amount.pesoFormatted,
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 22, tablet: 18, phone: 14),
              color: isDeduction ? ColorSet.secondary : ColorSet.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientButton(label: 'Apply', onPressed: onTap);
  }
}
