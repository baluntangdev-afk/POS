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
import '../../../utils/windows_touch_keyboard.dart';
import '../../../widgets/onscreen_keyboard/keyboard_suppress.dart';
import '../../../widgets/onscreen_keyboard/onscreen_keyboard.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/discount.dart';
import '../entities/line_item.dart';
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

    void onApplyDiscount(String? idNumber, String? beneficiaryName) {
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to discount.')),
        );
        return;
      }

      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => SeniorPwdDiscount(
            beneficiaryId: idNumber ?? '',
            beneficiaryName: beneficiaryName ?? '',
          ),
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
  final void Function(String? idNumber, String? beneficiaryName) onApplyDiscount;

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
  final void Function(String? idNumber, String? beneficiaryName) onApplyDiscount;

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
                                      image: NetworkImage(item.productImage),
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
  final void Function(String? idNumber, String? beneficiaryName) onApplyDiscount;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final idNumberController = useTextEditingController();
    final nameController = useTextEditingController();

    void validateAndSubmit() {
      if (formKey.currentState?.validate() ?? false) {
        onApplyDiscount(idNumberController.text, nameController.text);
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
                      if (selectedDiscountType == 'Senior/PWD') ...[
                        TextBoxFormField(
                          controller: idNumberController,
                          label: 'ID Number',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),
                        SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                        TextBoxFormField(
                          controller: nameController,
                          label: 'Name of ID Holder',
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          validator: Validate(rules: [isRequired()]).call,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                          ),
                        ),
                      ] else
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
      const discount = SeniorPwdDiscount(beneficiaryId: 'for_calculator_use_only', beneficiaryName: '');
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

// ─────────────────────────────────────────────────────────────────────────────
// Discount dialog
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showDiscountDialog(BuildContext context) {
  final r = context.responsive;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 40, tablet: 24, phone: 12),
        vertical: r.value<double>(kiosk: 40, tablet: 24, phone: 16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: r.value<double>(kiosk: 1100, tablet: 820, phone: double.infinity),
          maxHeight: r.value<double>(kiosk: 660, tablet: 580, phone: double.infinity),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
          child: const _DiscountDialogContent(),
        ),
      ),
    ),
  );
}

class _DiscountDialogContent extends HookConsumerWidget {
  const _DiscountDialogContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final items = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );

    final selectedDiscountType = useState('Senior/PWD');
    final selectedQuantities = useState<Map<String, int>>({});
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final codeController = useTextEditingController();
    final nameController = useTextEditingController();

    final selectableItems = useMemoized(
      () => items.where((e) => e.discount == null).toIList(),
      [items],
    );

    void onTypeChanged(String v) {
      selectedDiscountType.value = v;
      codeController.clear();
      nameController.clear();
      formKey.currentState?.reset();
    }

    void applyDiscount() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one item to discount.')),
        );
        return;
      }
      if (selectedDiscountType.value == 'Senior/PWD') {
        ref.read(orderingProvider.notifier).applyDiscount(
          selectedQuantities.value,
          (item, quantity) => SeniorPwdDiscount(
            beneficiaryId: codeController.text,
            beneficiaryName: nameController.text,
          ),
        );
      }
      if (context.mounted) Navigator.of(context).pop();
    }

    final selCount = selectedQuantities.value.length;

    return Material(
      color: ColorSet.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
              vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 12),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
              boxShadow: POSShadow.headerBottom,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: ColorSet.gradientBg,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(POSRadius.md),
                  ),
                  child: const Icon(Icons.sell_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Apply Discount',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                        fontWeight: FontWeight.w800,
                        color: POSColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      selCount > 0
                          ? '$selCount item${selCount == 1 ? "" : "s"} selected'
                          : 'Select items to apply discount',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
                        color: selCount > 0 ? ColorSet.primary : POSColors.textTertiary,
                        fontWeight: selCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: POSColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                      border: Border.all(color: POSColors.borderDefault),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: POSColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final isWide = constraints.maxWidth >= 600;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _DlgItemPanel(
                          items: items,
                          selectableItems: selectableItems,
                          selectedQuantities: selectedQuantities.value,
                          onChanged: (v) => selectedQuantities.value = v,
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: POSColors.borderDefault),
                      Expanded(
                        // flex: 45,
                        child: _DlgDiscountPanel(
                          formKey: formKey,
                          selectedType: selectedDiscountType.value,
                          onTypeChanged: onTypeChanged,
                          selectedQuantities: selectedQuantities.value,
                          codeController: codeController,
                          nameController: nameController,
                          onApply: applyDiscount,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _DlgItemPanel(
                        items: items,
                        selectableItems: selectableItems,
                        selectedQuantities: selectedQuantities.value,
                        onChanged: (v) => selectedQuantities.value = v,
                      ),
                    ),
                    Expanded(
                      child: _DlgDiscountPanel(
                        formKey: formKey,
                        selectedType: selectedDiscountType.value,
                        onTypeChanged: onTypeChanged,
                        selectedQuantities: selectedQuantities.value,
                        codeController: codeController,
                        nameController: nameController,
                        onApply: applyDiscount,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item selection panel ──────────────────────────────────────────────────────

class _DlgItemPanel extends ConsumerWidget {
  const _DlgItemPanel({
    required this.items,
    required this.selectableItems,
    required this.selectedQuantities,
    required this.onChanged,
  });

  final IList<LineItem> items;
  final IList<LineItem> selectableItems;
  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final allSelected = selectableItems.isNotEmpty &&
        selectableItems.every((e) => selectedQuantities.containsKey(e.id));
    final beneficiaryGroups = _groupDiscountedItemsByBeneficiary(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub-header
        Container(
          padding: EdgeInsets.fromLTRB(
            r.value<double>(kiosk: 16, tablet: 14, phone: 12),
            r.value<double>(kiosk: 10, tablet: 8, phone: 8),
            r.value<double>(kiosk: 16, tablet: 14, phone: 12),
            r.value<double>(kiosk: 10, tablet: 8, phone: 8),
          ),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.checklist_rounded, size: 15, color: POSColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'ORDER ITEMS',
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 10),
                  fontWeight: FontWeight.w700,
                  color: POSColors.textTertiary,
                  letterSpacing: 0.7,
                ),
              ),
              const Spacer(),
              if (selectableItems.isNotEmpty)
                GestureDetector(
                  onTap: () => allSelected
                      ? onChanged({})
                      : onChanged({for (final i in selectableItems) i.id: i.quantity}),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: allSelected
                          ? POSColors.surfaceSubtle
                          : ColorSet.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(POSRadius.full),
                      border: Border.all(
                        color: allSelected ? POSColors.borderStrong : ColorSet.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 10),
                        fontWeight: FontWeight.w700,
                        color: allSelected ? POSColors.textSecondary : ColorSet.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: POSColors.borderDefault),
        if (beneficiaryGroups.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in beneficiaryGroups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${group.beneficiaryName} (${group.beneficiaryId})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${group.itemIds.length} item${group.itemIds.length == 1 ? "" : "s"} · ${group.totalQuantity} qty',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _removeBeneficiaryDiscount(context, ref, group),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB91C1C),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            // shrinkWrap: true,
            padding: EdgeInsets.all(r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isDiscounted = item.discount != null;
              final selectedQty = selectedQuantities[item.id];
              final isSelected = selectedQty != null;
              final style = productPlaceholder(item.categoryName);
          
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AnimatedContainer(
                  duration: POSAnimation.fast,
                  decoration: BoxDecoration(
                    color: isDiscounted
                        ? const Color(0xFFFFF8EC)
                        : isSelected
                            ? ColorSet.primary.withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    border: Border.all(
                      color: isDiscounted
                          ? const Color(0xFFD97706).withValues(alpha: 0.5)
                          : isSelected
                              ? ColorSet.primary.withValues(alpha: 0.3)
                              : POSColors.borderSubtle,
                      width: isDiscounted || isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(POSRadius.md),
                      onTap: isDiscounted
                          ? null
                          : () {
                              final newMap = Map<String, int>.from(selectedQuantities);
                              if (isSelected) {
                                newMap.remove(item.id);
                              } else {
                                newMap[item.id] = item.quantity;
                              }
                              onChanged(newMap);
                            },
                      child: Padding(
                        padding: EdgeInsets.all(r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Checkbox / lock
                            AnimatedSwitcher(
                              duration: POSAnimation.fast,
                              child: isDiscounted
                                  ? Container(
                                      key: const ValueKey('locked'),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
                                      ),
                                      child: const Icon(Icons.lock_rounded, size: 11, color: Color(0xFFD97706)),
                                    )
                                  : SizedBox(
                                      key: const ValueKey('check'),
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: ColorSet.primary,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (value) {
                                          final newMap = Map<String, int>.from(selectedQuantities);
                                          if (value ?? false) {
                                            newMap[item.id] = item.quantity;
                                          } else {
                                            newMap.remove(item.id);
                                          }
                                          onChanged(newMap);
                                        },
                                      ),
                                    ),
                            ),
                            SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
          
                            // Thumbnail
                            Container(
                              width: r.value<double>(kiosk: 44, tablet: 38, phone: 34),
                              height: r.value<double>(kiosk: 44, tablet: 38, phone: 34),
                              decoration: BoxDecoration(
                                color: isDiscounted ? style.bg.withValues(alpha: 0.6) : style.bg,
                                borderRadius: BorderRadius.circular(POSRadius.sm),
                                image: item.productImage.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(item.productImage), fit: BoxFit.contain)
                                    : null,
                              ),
                              child: item.productImage.isEmpty
                                  ? Center(
                                      child: Opacity(
                                        opacity: isDiscounted ? 0.5 : 1.0,
                                        child: Icon(
                                          style.icon,
                                          size: r.value<double>(kiosk: 22, tablet: 17, phone: 15),
                                          color: style.fg,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
          
                            // Name + meta
                            Expanded(
                              child: Opacity(
                                opacity: isDiscounted ? 0.55 : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.productName} (${item.variant.name})',
                                      style: TextStyle(
                                        fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 12),
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? ColorSet.primary : POSColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    if (isDiscounted)
                                      const _AlreadyDiscountedBadge()
                                    else if (isSelected && item.quantity > 1)
                                      _DlgQtyStepper(
                                        value: selectedQty,
                                        max: item.quantity,
                                        onChanged: (qty) {
                                          final newMap = Map<String, int>.from(selectedQuantities);
                                          newMap[item.id] = qty;
                                          onChanged(newMap);
                                        },
                                      )
                                    else
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 10),
                                          color: POSColors.textTertiary,
                                        ),
                                      ),
                                    if (item.modifiers.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.modifiers.expand((m) => m.options).map((o) => o.name).join(', '),
                                        style: TextStyle(
                                          fontSize: r.value<double>(kiosk: 10, tablet: 9, phone: 9),
                                          color: POSColors.textTertiary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: r.value<double>(kiosk: 8, tablet: 6, phone: 6)),
          
                            // Price
                            Opacity(
                              opacity: isDiscounted ? 0.55 : 1.0,
                              child: Text(
                                item.grossAmount.pesoFormatted,
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 12),
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? ColorSet.primary : POSColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlreadyDiscountedBadge extends StatelessWidget {
  const _AlreadyDiscountedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 8, color: Color(0xFFD97706)),
          SizedBox(width: 3),
          Text(
            'Already Discounted',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }
}

class _DlgQtyStepper extends StatelessWidget {
  const _DlgQtyStepper({required this.value, required this.max, required this.onChanged});

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          icon: Icons.remove,
          color: ColorSet.primary,
          size: 22,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: POSColors.textPrimary),
        ),
        const SizedBox(width: 3),
        Text('/ $max', style: const TextStyle(fontSize: 10, color: POSColors.textTertiary)),
        const SizedBox(width: 8),
        _StepBtn(
          icon: Icons.add,
          color: ColorSet.primary,
          size: 22,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

// ── Discount controls panel ───────────────────────────────────────────────────

class _DlgDiscountPanel extends StatelessWidget {
  const _DlgDiscountPanel({
    required this.formKey,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedQuantities,
    required this.codeController,
    required this.nameController,
    required this.onApply,
  });

  final GlobalKey<FormState> formKey;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final Map<String, int> selectedQuantities;
  final TextEditingController codeController;
  final TextEditingController nameController;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final isSenior = selectedType == 'Senior/PWD';
    final codeLabel = isSenior ? 'ID Number' : 'Promo Code';
    final selCount = selectedQuantities.length;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-header
          Container(
            padding: EdgeInsets.fromLTRB(
              r.value<double>(kiosk: 16, tablet: 14, phone: 12),
              r.value<double>(kiosk: 10, tablet: 8, phone: 8),
              r.value<double>(kiosk: 16, tablet: 14, phone: 12),
              r.value<double>(kiosk: 10, tablet: 8, phone: 8),
            ),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, size: 15, color: POSColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'DISCOUNT DETAILS',
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 10),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textTertiary,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
              child: ListView(
                // crossAxisAlignment: CrossAxisAlignment.stretch,
                // mainAxisSize: MainAxisSize.min,
                shrinkWrap: true,
                children: [
                  // Compact pill type selector
                  _DlgTypePills(
                    selectedType: selectedType,
                    onTypeChanged: onTypeChanged,
                    r: r,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSenior ? '20% off + VAT Exempt' : 'Promo / coupon code',
                    style: const TextStyle(fontSize: 10, color: POSColors.textTertiary),
                  ),
                  SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                  Text(
                    codeLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: POSColors.textTertiary,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: codeController,
                    keyboardType: KeyboardSuppress.type(TextInputType.text),
                    textInputAction: TextInputAction.done,
                    readOnly: KeyboardSuppress.readOnly,
                    showCursor: KeyboardSuppress.showCursor,
                    onTap: KeyboardSuppress.onTap,
                    onTapOutside: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      OnScreenKeyboard.hide();
                      WindowsTouchKeyboard.dismiss();
                    },
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                      color: POSColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? '$codeLabel is required' : null,
                    decoration: InputDecoration(
                      hintText: isSenior ? 'e.g. SC-2024-00001' : 'Enter promo code...',
                      hintStyle: const TextStyle(
                        color: POSColors.textDisabled,
                        fontStyle: FontStyle.italic,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          isSenior ? Icons.badge_rounded : Icons.confirmation_number_outlined,
                          size: 18,
                          color: POSColors.textTertiary,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        borderSide: BorderSide(color: ColorSet.danger),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.md),
                        borderSide: BorderSide(color: ColorSet.danger, width: 1.5),
                      ),
                    ),
                  ),

                  if (isSenior) ...[
                    SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                    Text(
                      'NAME OF ID HOLDER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: POSColors.textTertiary,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      keyboardType: KeyboardSuppress.type(TextInputType.text),
                      textInputAction: TextInputAction.done,
                      readOnly: KeyboardSuppress.readOnly,
                      showCursor: KeyboardSuppress.showCursor,
                      onTap: KeyboardSuppress.onTap,
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        OnScreenKeyboard.hide();
                        WindowsTouchKeyboard.dismiss();
                      },
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
                        color: POSColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Name of ID Holder is required' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Juan Dela Cruz',
                        hintStyle: const TextStyle(
                          color: POSColors.textDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.person_outline_rounded, size: 18, color: POSColors.textTertiary),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
                          vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: POSColors.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: POSColors.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: BorderSide(color: ColorSet.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(POSRadius.md),
                          borderSide: BorderSide(color: ColorSet.danger, width: 1.5),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),

                  // Summary or empty hint — natural size, Spacer pins button to bottom
                  AnimatedSwitcher(
                    duration: POSAnimation.normal,
                    child: selectedQuantities.isEmpty
                        ? const _DlgEmptyGuide(key: ValueKey('empty'))
                        : _DlgSummary(
                            key: const ValueKey('summary'),
                            selectedQuantities: selectedQuantities,
                            selectedType: selectedType,
                          ),
                  ),



                  // Apply button — always visible, pinned at bottom

                  Gap(10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: selCount > 0
                          ? const LinearGradient(
                              colors: ColorSet.gradientBg,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selCount == 0 ? POSColors.borderStrong : null,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                      boxShadow: selCount > 0 ? POSShadow.button : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(POSRadius.full),
                        onTap: onApply,
                        child: SizedBox(
                          height: r.value<double>(kiosk: 52, tablet: 48, phone: 44),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: selCount > 0 ? 0.2 : 0.0),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: selCount > 0 ? Colors.white : POSColors.textDisabled,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selCount > 0
                                    ? 'Apply to $selCount item${selCount == 1 ? "" : "s"}'
                                    : 'Select items first',
                                style: TextStyle(
                                  fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                                  fontWeight: FontWeight.w700,
                                  color: selCount > 0 ? Colors.white : POSColors.textDisabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DlgTypePills extends StatelessWidget {
  const _DlgTypePills({
    required this.selectedType,
    required this.onTypeChanged,
    required this.r,
  });

  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final height = r.value<double>(kiosk: 48, tablet: 46, phone: 44);
    final isSenior = selectedType == 'Senior/PWD';

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.full),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Row(
        children: [
          _TypePill(
            icon: Icons.badge_rounded,
            label: 'Senior / PWD',
            isSelected: isSenior,
            onTap: () => onTypeChanged('Senior/PWD'),
          ),
          _TypePill(
            icon: Icons.sell_rounded,
            label: 'Promo',
            isSelected: !isSenior,
            onTap: () => onTypeChanged('Promo'),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: POSAnimation.fast,
          decoration: BoxDecoration(
            color: isSelected ? ColorSet.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(POSRadius.full),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : POSColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : POSColors.textSecondary,
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

class _DlgEmptyGuide extends StatelessWidget {
  const _DlgEmptyGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, size: 12, color: POSColors.textDisabled),
          SizedBox(width: 6),
          Text(
            'Select items to see breakdown',
            style: TextStyle(
              fontSize: 11,
              color: POSColors.textDisabled,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────────

class _DlgSummary extends ConsumerWidget {
  const _DlgSummary({super.key, required this.selectedQuantities, required this.selectedType});

  final Map<String, int> selectedQuantities;
  final String selectedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final lineItems = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );

    final grossAmount = selectedQuantities.entries.fold(Decimal.zero, (sum, entry) {
      try {
        final item = lineItems.firstWhere((e) => e.id == entry.key);
        final qty = Decimal.fromInt(entry.value);
        final modifiersPrice = item.modifiers.fold(Decimal.zero, (t, m) => t + m.price);
        return sum + qty * (item.variant.price + modifiersPrice);
      } catch (_) {
        return sum;
      }
    });

    var vatExempt = Decimal.zero;
    var discountAmount = Decimal.zero;

    if (selectedType == 'Senior/PWD') {
      const discount = SeniorPwdDiscount(beneficiaryId: '', beneficiaryName: '');
      vatExempt = grossAmount.vatAmount;
      discountAmount = discount.calculateAmount(grossAmount);
    }

    final afterDiscount = grossAmount - discountAmount - vatExempt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Column(
        children: [
          // Breakdown rows
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, vatExempt > Decimal.zero || discountAmount > Decimal.zero ? 8 : 12),
            child: Column(
              children: [
                _DlgSummaryRow(label: 'Selected Total', amount: grossAmount),
                if (vatExempt > Decimal.zero)
                  _DlgSummaryRow(label: 'VAT Exempt', amount: -vatExempt, isDeduction: true),
                if (discountAmount > Decimal.zero)
                  _DlgSummaryRow(label: 'Discount (20%)', amount: -discountAmount, isDeduction: true),
              ],
            ),
          ),

          // After Discount highlight
          if (discountAmount > Decimal.zero)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: ColorSet.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(POSRadius.sm),
                border: Border.all(color: ColorSet.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.savings_rounded, size: 14, color: ColorSet.primary),
                      const SizedBox(width: 6),
                      Text(
                        'After Discount',
                        style: TextStyle(
                          fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                          fontWeight: FontWeight.w700,
                          color: POSColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    afterDiscount.pesoFormatted,
                    style: TextStyle(
                      fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                      fontWeight: FontWeight.w800,
                      color: ColorSet.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DlgSummaryRow extends StatelessWidget {
  const _DlgSummaryRow({required this.label, required this.amount, this.isDeduction = false});

  final String label;
  final Decimal amount;
  final bool isDeduction;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final color = isDeduction ? const Color(0xFFDC2626) : POSColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 11),
              color: color,
            ),
          ),
          Text(
            amount.pesoFormatted,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 12, tablet: 11, phone: 11),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups items already carrying a Senior/PWD discount by beneficiary (name + id number).
List<_BeneficiaryGroup> _groupDiscountedItemsByBeneficiary(IList<LineItem> items) {
  final groups = <String, _BeneficiaryGroup>{};

  for (final item in items) {
    final discount = item.discount;
    if (discount is! SeniorPwdDiscount) continue;

    final key = '${discount.beneficiaryName}|${discount.beneficiaryId}';
    final existing = groups[key];
    if (existing == null) {
      groups[key] = _BeneficiaryGroup(
        beneficiaryName: discount.beneficiaryName,
        beneficiaryId: discount.beneficiaryId,
        itemIds: [item.id],
        totalQuantity: item.quantity,
      );
    } else {
      groups[key] = existing.copyWith(
        itemIds: [...existing.itemIds, item.id],
        totalQuantity: existing.totalQuantity + item.quantity,
      );
    }
  }

  return groups.values.toList();
}

class _BeneficiaryGroup {
  const _BeneficiaryGroup({
    required this.beneficiaryName,
    required this.beneficiaryId,
    required this.itemIds,
    required this.totalQuantity,
  });

  final String beneficiaryName;
  final String beneficiaryId;
  final List<String> itemIds;
  final int totalQuantity;

  _BeneficiaryGroup copyWith({List<String>? itemIds, int? totalQuantity}) => _BeneficiaryGroup(
    beneficiaryName: beneficiaryName,
    beneficiaryId: beneficiaryId,
    itemIds: itemIds ?? this.itemIds,
    totalQuantity: totalQuantity ?? this.totalQuantity,
  );
}

/// Unlocks every item in [group] by resolving each item id to its current index in the sale and
/// clearing the discount there. Clears from the highest index down so earlier removals don't
/// shift the indices of items still pending removal.
void _removeBeneficiaryDiscount(BuildContext context, WidgetRef ref, _BeneficiaryGroup group) {
  final items = ref.read(orderingProvider).value?.sale.items ?? const IList.empty();
  final indexes = [
    for (final itemId in group.itemIds) items.indexWhere((e) => e.id == itemId),
  ]..sort((a, b) => b.compareTo(a));

  for (final index in indexes) {
    if (index == -1) continue;
    ref.read(orderingProvider.notifier).clearDiscount(index: index);
  }
}
