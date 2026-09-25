import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/form_sheet_scaffold.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';
import 'product_form_dialog.dart';

/// The fast path for the two edits made most often at the counter —
/// availability and price. Everything else (name, photo, category,
/// variant structure, modifiers) stays in [ProductFormDialog].
class ProductQuickEditSheet extends ConsumerStatefulWidget {
  final InventoryProduct product;

  const ProductQuickEditSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, InventoryProduct product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductQuickEditSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductQuickEditSheet> createState() => _ProductQuickEditSheetState();
}

class _ProductQuickEditSheetState extends ConsumerState<ProductQuickEditSheet> {
  late bool _isAvailable = widget.product.isAvailable;
  List<ProductVariantsTableData>? _variants;
  Object? _loadError;
  final _priceCtrls = <int, TextEditingController>{};
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Read straight from the DB rather than the cached productVariantsProvider
    // so the prices shown are never stale.
    ref
        .read(databaseProvider)
        .productsDao
        .getVariantsForProduct(widget.product.id)
        .then(
          (rows) {
            if (!mounted) return;
            setState(() {
              _variants = rows;
              for (final v in rows.where((v) => v.isActive)) {
                _priceCtrls[v.id] = TextEditingController(text: v.price.toStringAsFixed(2));
              }
            });
          },
          onError: (Object e) {
            if (mounted) setState(() => _loadError = e);
          },
        );
  }

  @override
  void dispose() {
    for (final c in _priceCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _pricesChanged() => _variants!.any((v) {
        final ctrl = _priceCtrls[v.id];
        return ctrl != null && double.tryParse(ctrl.text.trim()) != v.price;
      });

  Future<void> _save() async {
    final variants = _variants;
    if (variants == null) return;
    for (final c in _priceCtrls.values) {
      final price = double.tryParse(c.text.trim());
      if (price == null || price < 0.01) {
        setState(() => _error = 'Each price must be at least 0.01');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final notifier = ref.read(inventoryNotifierProvider.notifier);
    try {
      if (_pricesChanged()) {
        await notifier.saveVariants(
          widget.product.id,
          [
            for (final v in variants)
              VariantInput(
                id: v.id,
                name: v.name,
                price: double.tryParse(_priceCtrls[v.id]?.text.trim() ?? '') ?? v.price,
                isDefault: v.isDefault,
                isActive: v.isActive,
              ),
          ],
        );
      }
      if (_isAvailable != widget.product.isAvailable) {
        await notifier.setAvailability([widget.product.id], isAvailable: _isAvailable);
      }
      ref.invalidate(productVariantsProvider(widget.product.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openFullEditor() {
    final product = widget.product;
    final navigator = Navigator.of(context);
    navigator.pop();
    ProductFormDialog.show(navigator.context, existing: product, groupId: product.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = _variants;
    final active = variants?.where((v) => v.isActive).toList() ?? const [];

    return FormSheetScaffold(
      title: product.name,
      confirmLabel: 'Save changes',
      isSaving: _isSaving,
      onCancel: () => Navigator.pop(context),
      onConfirm: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (product.group != null)
            Text(product.group!.name,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
          const Gap(AppSpacing.md),
          _AvailabilityTile(
            value: _isAvailable,
            onChanged: _isSaving ? null : (v) => setState(() => _isAvailable = v),
          ),
          const Gap(AppSpacing.lg),
          Text('Prices', style: AppTextStyles.headingSm),
          const Gap(AppSpacing.sm),
          if (_loadError != null)
            Text(_loadError.toString(),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))
          else if (variants == null)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (active.isEmpty)
            Text('No active variants — use full edit to add one.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary))
          else
            _PriceList(variants: active, controllers: _priceCtrls, enabled: !_isSaving),
          if (_error != null) ...[
            const Gap(AppSpacing.sm),
            Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
          ],
          const Gap(AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _openFullEditor,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            label: Text('Edit name, photo, category & variants', style: AppTextStyles.headingSm),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _AvailabilityTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? AppColors.primary.withValues(alpha: 0.10) : AppColors.warningLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        title: Text(value ? 'Available on menu' : 'Hidden from menu',
            style: AppTextStyles.headingSm),
        subtitle: Text(
          value ? 'Cashiers can sell this item' : 'Cashiers won\'t see this item',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _PriceList extends StatelessWidget {
  final List<ProductVariantsTableData> variants;
  final Map<int, TextEditingController> controllers;
  final bool enabled;

  const _PriceList({required this.variants, required this.controllers, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < variants.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.surfaceVariant),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(variants[i].name, style: AppTextStyles.headingSm),
                        if (variants[i].isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text('Default',
                                style: AppTextStyles.labelMd
                                    .copyWith(color: AppColors.textSecondary)),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: controllers[variants[i].id],
                      enabled: enabled,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: AppTextStyles.priceMd,
                      decoration: InputDecoration(
                        prefixText: 'PHP ',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
