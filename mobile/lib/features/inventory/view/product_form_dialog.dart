import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/popup_menu_form_field.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';

class _VariantRow {
  int? id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  bool isDefault;
  bool isActive;

  _VariantRow({
    this.id,
    required String name,
    required String price,
    required this.isDefault,
    required this.isActive,
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price);

  factory _VariantRow.blank({bool isDefault = false}) =>
      _VariantRow(name: '', price: '', isDefault: isDefault, isActive: true);

  factory _VariantRow.fromData(ProductVariantsTableData row) => _VariantRow(
        id: row.id,
        name: row.name,
        price: _formatPrice(row.price),
        isDefault: row.isDefault,
        isActive: row.isActive,
      );

  static String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Create/edit dialog for an inventory product, including its variants.
///
/// [existing] is `null` for create-mode; passing a [InventoryProduct] switches
/// to edit-mode, seeding the variants editor from [productVariantsProvider].
class ProductFormDialog extends ConsumerStatefulWidget {
  final InventoryProduct? existing;
  final int? groupId;

  const ProductFormDialog({super.key, this.existing, this.groupId});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedGroupId;
  String? _imageUrl;
  String? _nameError;
  String? _variantsError;
  bool _isSaving = false;
  bool _variantsLoaded = false;
  List<_VariantRow> _variants = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    final candidateGroupId = existing?.groupId ?? widget.groupId;
    final loadedGroups = ref.read(inventoryNotifierProvider).value?.groups ?? const [];
    _selectedGroupId =
        (candidateGroupId != null && loadedGroups.any((g) => g.id == candidateGroupId))
            ? candidateGroupId
            : null;
    _imageUrl = existing?.imageUrl;

    if (_isEditing) {
      _loadVariants();
    } else {
      _variants = [_VariantRow.blank(isDefault: true)];
      _variantsLoaded = true;
    }
  }

  Future<void> _loadVariants() async {
    final rows = await ref.read(productVariantsProvider(widget.existing!.id).future);
    if (!mounted) return;
    setState(() {
      _variants = rows.isEmpty
          ? [_VariantRow.blank(isDefault: true)]
          : rows.map((r) => _VariantRow.fromData(r)).toList();
      _variantsLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageStorageService.pickAndStore();
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _imageUrl = picked);
  }

  void _removeImage() => setState(() => _imageUrl = null);

  void _addVariant() {
    setState(() => _variants.add(_VariantRow.blank()));
  }

  void _removeVariant(int index) {
    final v = _variants[index];
    if (v.id == null) {
      setState(() {
        v.dispose();
        _variants.removeAt(index);
      });
    } else {
      setState(() => v.isActive = false);
    }
    _reassignDefaultIfNeeded();
  }

  void _setActive(int index, bool value) {
    setState(() => _variants[index].isActive = value);
    _reassignDefaultIfNeeded();
  }

  void _setDefault(int index) {
    setState(() {
      for (var i = 0; i < _variants.length; i++) {
        _variants[i].isDefault = i == index;
      }
    });
  }

  void _reassignDefaultIfNeeded() {
    final active = _variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return;
    final hasActiveDefault = active.any((v) => v.isDefault);
    if (!hasActiveDefault) {
      setState(() {
        for (final v in _variants) {
          v.isDefault = false;
        }
        active.first.isDefault = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = null;
      _variantsError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGroupId == null) return;

    final active = _variants.where((v) => v.isActive).toList();
    if (active.isEmpty) {
      setState(() => _variantsError = 'At least one active variant is required');
      return;
    }
    final names = active.map((v) => v.nameCtrl.text.trim().toLowerCase()).toList();
    if (names.any((n) => n.isEmpty)) {
      setState(() => _variantsError = 'Every active variant needs a name');
      return;
    }
    if (names.toSet().length != names.length) {
      setState(() => _variantsError = 'Variant names must be unique');
      return;
    }
    for (final v in active) {
      final price = double.tryParse(v.priceCtrl.text.trim());
      if (price == null || price < 0.01) {
        setState(() => _variantsError = 'Each active variant needs a price of at least 0.01');
        return;
      }
    }
    if (!active.any((v) => v.isDefault)) {
      setState(() => _variantsError = 'Exactly one active variant must be marked default');
      return;
    }

    final name = _nameController.text.trim();
    final groupId = _selectedGroupId!;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(inventoryNotifierProvider.notifier);
      final int productId;
      if (_isEditing) {
        productId = widget.existing!.id;
        await notifier.updateProduct(
          id: productId,
          groupId: groupId,
          name: name,
          imageUrl: _imageUrl,
        );
      } else {
        productId = await notifier.createProduct(
          groupId: groupId,
          name: name,
          imageUrl: _imageUrl,
        );
      }

      await notifier.saveVariants(
        productId,
        _variants
            .map((v) => VariantInput(
                  id: v.id,
                  name: v.nameCtrl.text.trim(),
                  price: double.tryParse(v.priceCtrl.text.trim()) ?? 0,
                  isDefault: v.isDefault,
                  isActive: v.isActive,
                ))
            .toList(),
      );

      if (mounted) Navigator.pop(context);
    } on StateError catch (e) {
      setState(() => _nameError = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryNotifierProvider).value;
    final groups = inventoryState?.groups ?? const [];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const Gap(AppSpacing.md),
                PopupMenuFormField<int>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: groups
                      .map((g) => PopupMenuFormFieldItem(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
                const Gap(AppSpacing.lg),
                Text('Image', style: AppTextStyles.labelLg.copyWith(color: AppColors.textSecondary)),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    _ImageThumbnail(imageUrl: _imageUrl),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(_imageUrl == null ? 'Choose Image' : 'Change Image'),
                          ),
                          if (_imageUrl != null)
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                              label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Variants', style: AppTextStyles.labelLg.copyWith(color: AppColors.textSecondary)),
                    TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Variant'),
                    ),
                  ],
                ),
                if (_variantsError != null) ...[
                  const Gap(4),
                  Text(_variantsError!, style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                ],
                const Gap(AppSpacing.sm),
                if (!_variantsLoaded)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (var i = 0; i < _variants.length; i++)
                    _VariantRowWidget(
                      key: ValueKey(_variants[i]),
                      row: _variants[i],
                      onRemove: () => _removeVariant(i),
                      onToggleActive: (v) => _setActive(i, v),
                      onSetDefault: () => _setDefault(i),
                    ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _VariantRowWidget extends StatelessWidget {
  final _VariantRow row;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onSetDefault;

  const _VariantRowWidget({
    super.key,
    required this.row,
    required this.onRemove,
    required this.onToggleActive,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = row.id == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.nameCtrl,
              decoration: const InputDecoration(labelText: 'Variant name', isDense: true),
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.priceCtrl,
              decoration: const InputDecoration(labelText: 'Price', prefixText: 'PHP ', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            ),
          ),
          const Gap(AppSpacing.sm),
          IconButton(
            tooltip: row.isDefault ? 'Default variant' : 'Make default',
            icon: Icon(
              row.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
              color: row.isDefault ? AppColors.secondary : AppColors.textDisabled,
            ),
            onPressed: row.isActive ? onSetDefault : null,
          ),
          if (isNew)
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: onRemove,
            )
          else
            Switch(
              value: row.isActive,
              onChanged: onToggleActive,
            ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _ImageThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 64,
        height: 64,
        color: AppColors.surfaceVariant,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Icon(Icons.image_outlined, color: AppColors.textDisabled);
    }
    if (ImageStorageService.isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, e, st) => Icon(Icons.broken_image_outlined, color: AppColors.textDisabled),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (context, e, st) => Icon(Icons.broken_image_outlined, color: AppColors.textDisabled),
    );
  }
}
