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
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/tax_calculator.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/discount.dart';
import '../state/ordering_notifier.dart';

class DiscountScreen extends HookConsumerWidget {
  const DiscountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountTypes = useMemoized(() => ['Senior/PWD', 'Promo']);
    final selectedDiscountType = useState('Senior/PWD');
    final initialSelected = useMemoized(() {
      final items = ref.read(orderingProvider).value?.sale.items ?? const IList.empty();
      return <String, int>{
        for (final item in items.where((e) => e.discount != null)) item.id: item.quantity,
      };
    });
    final selectedQuantities = useState<Map<String, int>>(initialSelected);
    final isAndroid = context.breakpoint.isAndroid;

    void onApplyDiscount(String? idNumber) {
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to discount.')),
        );
        return;
      }

      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => SeniorPwdDiscount(beneficiaryId: idNumber ?? ''),
        );
      } else {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => null,
        );
      }
      context.pop();
    }

    final body = Column(
      children: [
        const _FlatHeader(title: 'Apply Discount'),
        Expanded(
          child: ResponsiveBuilder(
            kiosk: (context) => _LandscapeLayout(
              selectedQuantities: selectedQuantities.value,
              onQuantitiesChanged: (val) => selectedQuantities.value = val,
              discountTypes: discountTypes,
              selectedDiscountType: selectedDiscountType.value,
              onDiscountTypeChanged: (val) => selectedDiscountType.value = val,
              onApplyDiscount: onApplyDiscount,
            ),
            tablet: (context) => _LandscapeLayout(
              selectedQuantities: selectedQuantities.value,
              onQuantitiesChanged: (val) => selectedQuantities.value = val,
              discountTypes: discountTypes,
              selectedDiscountType: selectedDiscountType.value,
              onDiscountTypeChanged: (val) => selectedDiscountType.value = val,
              onApplyDiscount: onApplyDiscount,
            ),
            phone: (context) => _PortraitLayout(
              selectedQuantities: selectedQuantities.value,
              onQuantitiesChanged: (val) => selectedQuantities.value = val,
              discountTypes: discountTypes,
              selectedDiscountType: selectedDiscountType.value,
              onDiscountTypeChanged: (val) => selectedDiscountType.value = val,
              onApplyDiscount: onApplyDiscount,
            ),
          ),
        ),
      ],
    );

    if (isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        body: SafeArea(child: body),
      );
    }

    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }
}

// ── Flat white header (consistent with cart/payment) ──────────────────────────
class _FlatHeader extends StatelessWidget {
  const _FlatHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 68, tablet: 60, phone: 52);
    final btnH = r.value<double>(kiosk: 44, tablet: 40, phone: 36);

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 24, tablet: 16, phone: 12),
      ),
      child: Row(
        children: [
          SizedBox(
            height: btnH,
            child: OutlinedButton.icon(
              onPressed: () {
                if (context.canPop()) context.pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
              ),
              label: Text(
                'Back',
                style: TextStyle(fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.6), width: 1.5),
                padding: EdgeInsets.symmetric(
                  horizontal: r.value<double>(kiosk: 16, tablet: 12, phone: 10),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 20, tablet: 17, phone: 15),
              fontWeight: FontWeight.w700,
              color: POSColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          SizedBox(width: r.value<double>(kiosk: 90, tablet: 76, phone: 64)),
        ],
      ),
    );
  }
}

// ── Layouts ───────────────────────────────────────────────────────────────────
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

// ── Item selection panel ──────────────────────────────────────────────────────
class _LineItemSelectionView extends ConsumerWidget {
  const _LineItemSelectionView({
    required this.selectedQuantities,
    required this.onQuantitiesChanged,
  });

  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onQuantitiesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final lineItems = ref.watch(
      orderingProvider.select(
        (it) => it.value?.sale.items ?? const IList.empty(),
      ),
    );

    return Container(
      margin: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Panel header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value<double>(kiosk: 20, tablet: 16, phone: 14),
              vertical: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ColorSet.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(POSRadius.xs),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: ColorSet.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Items',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                        fontWeight: FontWeight.w700,
                        color: POSColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (selectedQuantities.length == lineItems.length) {
                      onQuantitiesChanged({});
                    } else {
                      onQuantitiesChanged({
                        for (final item in lineItems) item.id: item.quantity,
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: ColorSet.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    selectedQuantities.length == lineItems.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
              itemCount: lineItems.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: POSColors.borderSubtle,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final item = lineItems[index];
                final selectedQty = selectedQuantities[item.id];
                final isSelected = selectedQty != null;
                final style = productPlaceholder(item.categoryName);

                return Material(
                  color: isSelected
                      ? ColorSet.primary.withValues(alpha: 0.03)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final newMap = Map<String, int>.from(selectedQuantities);
                      if (isSelected) {
                        newMap.remove(item.id);
                      } else {
                        newMap[item.id] = item.quantity;
                      }
                      onQuantitiesChanged(newMap);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                        horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: ColorSet.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(POSRadius.xs),
                              ),
                              onChanged: (value) {
                                final newMap = Map<String, int>.from(selectedQuantities);
                                if (value ?? false) {
                                  newMap[item.id] = item.quantity;
                                } else {
                                  newMap.remove(item.id);
                                }
                                onQuantitiesChanged(newMap);
                              },
                            ),
                          ),
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          // Product image
                          Container(
                            width: r.value<double>(kiosk: 64, tablet: 52, phone: 44),
                            height: r.value<double>(kiosk: 64, tablet: 52, phone: 44),
                            decoration: BoxDecoration(
                              color: item.productImage.isEmpty
                                  ? style.bg
                                  : ColorSet.background,
                              borderRadius: BorderRadius.circular(POSRadius.md),
                              image: item.productImage.isNotEmpty
                                  ? DecorationImage(
                                      image: MemoryImage(item.productImage),
                                      fit: BoxFit.contain,
                                    )
                                  : null,
                            ),
                            child: item.productImage.isEmpty
                                ? Center(
                                    child: Icon(
                                      style.icon,
                                      size: r.value<double>(kiosk: 32, tablet: 26, phone: 22),
                                      color: style.fg,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.variant.name.isNotEmpty ? "${item.variant.name} " : ""}${item.productName}',
                                  style: TextStyle(
                                    fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                                    fontWeight: FontWeight.w600,
                                    color: POSColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (item.discount != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ColorSet.danger.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(POSRadius.xs),
                                      border: Border.all(color: ColorSet.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'LESS: ${item.discount!.code}',
                                      style: TextStyle(
                                        fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 9),
                                        color: ColorSet.danger,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isSelected && item.quantity > 1) ...[
                                  _QuantityStepper(
                                    value: selectedQty,
                                    max: item.quantity,
                                    onChanged: (qty) {
                                      final newMap = Map<String, int>.from(selectedQuantities);
                                      newMap[item.id] = qty;
                                      onQuantitiesChanged(newMap);
                                    },
                                    r: r,
                                  ),
                                ] else ...[
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: TextStyle(
                                      fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                                      color: POSColors.textTertiary,
                                    ),
                                  ),
                                ],
                                if (item.modifiers.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.modifiers
                                        .expand((m) => m.options)
                                        .map((o) => o.name)
                                        .join(', '),
                                    style: TextStyle(
                                      fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                                      color: POSColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                          Text(
                            item.grossAmount.pesoFormatted,
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                              fontWeight: FontWeight.w700,
                              color: isSelected ? ColorSet.primary : POSColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.r,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final btnSize = r.value<double>(kiosk: 28, tablet: 24, phone: 20);
    final textSize = r.value<double>(kiosk: 15, tablet: 13, phone: 12);

    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove,
          color: ColorSet.primary,
          size: btnSize,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(width: r.value<double>(kiosk: 14, tablet: 10, phone: 8)),
        Text(
          '$value',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w700,
            color: POSColors.textPrimary,
          ),
        ),
        SizedBox(width: r.value<double>(kiosk: 6, tablet: 5, phone: 4)),
        Text(
          'of $max',
          style: TextStyle(
            fontSize: textSize - 1,
            color: POSColors.textTertiary,
          ),
        ),
        SizedBox(width: r.value<double>(kiosk: 8, tablet: 6, phone: 5)),
        _StepBtn(
          icon: Icons.add,
          color: ColorSet.primary,
          size: btnSize,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.color, required this.size, this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: onTap != null ? color.withValues(alpha: 0.1) : POSColors.borderStrong,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Icon(
            icon,
            color: onTap != null ? color : POSColors.textDisabled,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

// ── Discount controls panel ───────────────────────────────────────────────────
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
    final r = context.responsive;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final idNumberController = useTextEditingController();

    void validateAndSubmit() {
      if (formKey.currentState?.validate() ?? false) {
        onApplyDiscount(idNumberController.text);
      }
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        r.value<double>(kiosk: 0, tablet: 0, phone: 12),
        r.value<double>(kiosk: 20, tablet: 16, phone: 0),
        r.value<double>(kiosk: 20, tablet: 16, phone: 12),
        r.value<double>(kiosk: 20, tablet: 16, phone: 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Form(
        key: formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 14)),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ColorSet.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(POSRadius.xs),
                            ),
                            child: const Icon(
                              Icons.local_offer_rounded,
                              color: ColorSet.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Discount Type',
                            style: TextStyle(
                              fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                              fontWeight: FontWeight.w700,
                              color: POSColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),

                      // Type toggle buttons
                      Row(
                        children: discountTypes.map((type) {
                          final isSelected = selectedDiscountType == type;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: type == discountTypes.last ? 0 : 8,
                              ),
                              child: AnimatedContainer(
                                duration: POSAnimation.fast,
                                height: r.value<double>(kiosk: 48, tablet: 44, phone: 40),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ColorSet.primary
                                      : POSColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(POSRadius.md),
                                  border: Border.all(
                                    color: isSelected
                                        ? ColorSet.primary
                                        : POSColors.borderDefault,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(POSRadius.md),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(POSRadius.md),
                                    onTap: () => onDiscountTypeChanged(type),
                                    child: Center(
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : POSColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 14)),

                      // ID / Promo field
                      if (selectedDiscountType == 'Senior/PWD')
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'ID Number',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        )
                      else
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'Promo Code',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),

                      const Spacer(),

                      // Summary section
                      _SummarySection(
                        selectedQuantities: selectedQuantities,
                        selectedDiscountType: selectedDiscountType,
                      ),
                      SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),

                      // Apply button
                      _ApplyButton(onTap: validateAndSubmit),
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
  const _SummarySection({
    required this.selectedQuantities,
    required this.selectedDiscountType,
  });

  final Map<String, int> selectedQuantities;
  final String selectedDiscountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
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

    if (selectedQuantities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Selected Total', amount: grossAmount),
          if (vatExempt > Decimal.zero)
            _SummaryRow(label: 'VAT Exempt', amount: -vatExempt, isDeduction: true),
          if (discountAmount > Decimal.zero)
            _SummaryRow(label: 'Discount', amount: -discountAmount, isDeduction: true),
        ],
      ),
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
    final r = context.responsive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
              color: isDeduction ? ColorSet.danger : POSColors.textSecondary,
            ),
          ),
          Text(
            amount.pesoFormatted,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
              fontWeight: FontWeight.w600,
              color: isDeduction ? ColorSet.danger : POSColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final height = r.value<double>(kiosk: 60, tablet: 56, phone: 52);
    const radius = POSRadius.full;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: ColorSet.gradientBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: POSShadow.button,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Apply Discount',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
