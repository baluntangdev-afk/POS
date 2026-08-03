import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_filled_button.dart';
import '../entities/discount.dart';
import '../entities/line_item.dart';
import '../state/ordering_notifier.dart';

class DiscountScreen extends HookConsumerWidget {
  const DiscountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountTypes = useMemoized(() => const ['Senior/PWD', 'Promo']);
    final selectedType = useState('Senior/PWD');
    final selectedQuantities = useState<Map<String, int>>({});
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final idController = useTextEditingController();
    final nameController = useTextEditingController();

    final items = ref.watch(
      orderingProvider.select((s) => s.value?.sale.items ?? const <LineItem>[]),
    );
    final selectableItems = items.where((i) => i.discount == null).toList();

    void onTypeChanged(String type) {
      selectedType.value = type;
      idController.clear();
      nameController.clear();
      formKey.currentState?.reset();
    }

    void applyDiscount() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (selectedQuantities.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one item to discount.'),
          ),
        );
        return;
      }

      if (selectedType.value == 'Senior/PWD') {
        ref
            .read(orderingProvider.notifier)
            .applyDiscount(
              selectedQuantities.value,
              (item, quantity) => SeniorPwdDiscount(
                beneficiaryId: idController.text.trim(),
                beneficiaryName: nameController.text.trim(),
              ),
            );
      } else {
        ref
            .read(orderingProvider.notifier)
            .applyDiscount(
              selectedQuantities.value,
              (item, quantity) => PromoDiscount(code: idController.text.trim()),
            );
      }
      if (context.mounted) context.pop();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apply Discount'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _ItemSelectionList(
              items: items,
              selectableItems: selectableItems,
              selectedQuantities: selectedQuantities.value,
              onChanged: (v) => selectedQuantities.value = v,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: _DiscountControls(
                formKey: formKey,
                discountTypes: discountTypes,
                selectedType: selectedType.value,
                onTypeChanged: onTypeChanged,
                idController: idController,
                nameController: nameController,
                selectedQuantities: selectedQuantities.value,
                items: items,
                onApply: applyDiscount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSelectionList extends StatelessWidget {
  const _ItemSelectionList({
    required this.items,
    required this.selectableItems,
    required this.selectedQuantities,
    required this.onChanged,
  });

  final List<LineItem> items;
  final List<LineItem> selectableItems;
  final Map<String, int> selectedQuantities;
  final ValueChanged<Map<String, int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        selectableItems.isNotEmpty &&
        selectableItems.every((e) => selectedQuantities.containsKey(e.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'SELECT ITEMS',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textDisabled,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (selectableItems.isNotEmpty)
                TextButton(
                  onPressed:
                      () =>
                          allSelected
                              ? onChanged({})
                              : onChanged({
                                for (final i in selectableItems)
                                  i.id: i.quantity,
                              }),
                  child: Text(allSelected ? 'Deselect All' : 'Select All'),
                ),
            ],
          ),
        ),
        Expanded(
          child:
              items.isEmpty
                  ? Center(
                    child: Text(
                      'No items in cart',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isDiscounted = item.discount != null;
                      final selectedQty = selectedQuantities[item.id];
                      final isSelected = selectedQty != null;

                      return _ItemRow(
                        item: item,
                        isDiscounted: isDiscounted,
                        isSelected: isSelected,
                        selectedQty: selectedQty,
                        onToggle:
                            isDiscounted
                                ? null
                                : (selected) {
                                  final newMap = Map<String, int>.from(
                                    selectedQuantities,
                                  );
                                  if (selected) {
                                    newMap[item.id] = item.quantity;
                                  } else {
                                    newMap.remove(item.id);
                                  }
                                  onChanged(newMap);
                                },
                        onQuantityChanged: (qty) {
                          final newMap = Map<String, int>.from(
                            selectedQuantities,
                          );
                          newMap[item.id] = qty;
                          onChanged(newMap);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isDiscounted,
    required this.isSelected,
    required this.selectedQty,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final LineItem item;
  final bool isDiscounted;
  final bool isSelected;
  final int? selectedQty;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDiscounted
                ? AppColors.warningLight
                : isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              isDiscounted
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onToggle == null ? null : () => onToggle!(!isSelected),
          leading:
              isDiscounted
                  ? const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: AppColors.warning,
                  )
                  : Checkbox(
                    value: isSelected,
                    onChanged: (v) => onToggle?.call(v ?? false),
                  ),
          title: Text(
            item.productName,
            style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle:
              isDiscounted
                  ? const Text(
                    'Already Discounted',
                    style: TextStyle(color: AppColors.warning, fontSize: 11),
                  )
                  : isSelected && item.quantity > 1
                  ? _QtyStepper(
                    value: selectedQty!,
                    max: item.quantity,
                    onChanged: onQuantityChanged,
                  )
                  : Text(
                    'Qty: ${item.quantity}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
          trailing: Text(
            'PHP ${item.lineSubtotal.toStringAsFixed(2)}',
            style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.remove_circle_outline, size: 18),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value / $max', style: AppTextStyles.bodySm),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _DiscountControls extends StatelessWidget {
  const _DiscountControls({
    required this.formKey,
    required this.discountTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.idController,
    required this.nameController,
    required this.selectedQuantities,
    required this.items,
    required this.onApply,
  });

  final GlobalKey<FormState> formKey;
  final List<String> discountTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final TextEditingController idController;
  final TextEditingController nameController;
  final Map<String, int> selectedQuantities;
  final List<LineItem> items;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final selectedSubtotal = selectedQuantities.entries.fold(0.0, (sum, entry) {
      final item = items.firstWhere((i) => i.id == entry.key);
      return sum + item.unitPrice * entry.value;
    });
    final vatExempt =
        selectedType == 'Senior/PWD' ? selectedSubtotal.vatAmount : 0.0;
    final discountAmount =
        selectedType == 'Senior/PWD'
            ? const SeniorPwdDiscount(
              beneficiaryId: '',
              beneficiaryName: '',
            ).calculateAmount(selectedSubtotal)
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children:
                  discountTypes.map((type) {
                    final isSelected = type == selectedType;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: type == discountTypes.last ? 0 : 8,
                        ),
                        child: OutlinedButton(
                          onPressed: () => onTypeChanged(type),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                isSelected ? AppColors.primary : null,
                            foregroundColor:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(type),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const Gap(AppSpacing.sm),
            if (selectedType == 'Senior/PWD') ...[
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Number'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const Gap(AppSpacing.sm),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name of ID Holder',
                ),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ] else
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Promo Code'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            if (selectedQuantities.isNotEmpty) ...[
              const Gap(AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    _SummaryRow('Selected Total', selectedSubtotal),
                    if (vatExempt > 0) _SummaryRow('VAT Exempt', -vatExempt),
                    if (discountAmount > 0)
                      _SummaryRow('Discount', -discountAmount),
                  ],
                ),
              ),
            ],
            const Gap(AppSpacing.md),
            GradientFilledButton(
              onPressed: onApply,
              minHeight: 52,
              child: const Text('Apply Discount'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount);

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final isDeduction = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: isDeduction ? AppColors.error : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            '${amount < 0 ? '-' : ''}PHP ${amount.abs().toStringAsFixed(2)}',
            style: AppTextStyles.bodySm.copyWith(
              color: isDeduction ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
