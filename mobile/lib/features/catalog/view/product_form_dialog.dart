import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/catalog_product.dart';
import '../state/catalog_notifier.dart';

/// Create/edit dialog for a catalog product.
///
/// [existing] is `null` for create-mode; passing a [CatalogProduct] switches
/// to edit-mode. We take the lighter [CatalogProduct] entity (rather than the
/// raw `ProductsTableData` row) because it already carries every field this
/// form needs (id/groupId/name/price/imageUrl) — fetching the raw row from
/// the DAO would be an unnecessary extra round-trip.
class ProductFormDialog extends ConsumerStatefulWidget {
  final CatalogProduct? existing;
  final int? groupId;

  const ProductFormDialog({super.key, this.existing, this.groupId});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  int? _selectedGroupId;
  String? _imageUrl;
  String? _nameError;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController =
        TextEditingController(text: existing != null ? _formatPrice(existing.price) : '');
    final candidateGroupId = existing?.groupId ?? widget.groupId;
    // `CatalogNotifier.groups` only lists ACTIVE categories, but a product's own
    // `groupId` may belong to a category that has since been deactivated. If we set
    // `_selectedGroupId` to a value that isn't among the dropdown's items,
    // DropdownButtonFormField asserts/crashes (its value must be null or match an
    // item exactly). Fall back to null in that case and require the user to pick an
    // active category explicitly — the existing "category required" validator
    // already enforces this before save.
    final loadedGroups = ref.read(catalogNotifierProvider).value?.groups ?? const [];
    _selectedGroupId =
        (candidateGroupId != null && loadedGroups.any((g) => g.id == candidateGroupId))
            ? candidateGroupId
            : null;
    _imageUrl = existing?.imageUrl;
  }

  String _formatPrice(double price) =>
      price == price.roundToDouble() ? price.toStringAsFixed(0) : price.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageStorageService.pickAndStore();
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _imageUrl = picked);
  }

  void _removeImage() {
    setState(() => _imageUrl = null);
  }

  Future<void> _submit() async {
    setState(() => _nameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGroupId == null) return;

    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final groupId = _selectedGroupId!;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(catalogNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateProduct(
          id: widget.existing!.id,
          groupId: groupId,
          name: name,
          price: price,
          imageUrl: _imageUrl,
        );
      } else {
        await notifier.createProduct(
          groupId: groupId,
          name: name,
          price: price,
          imageUrl: _imageUrl,
        );
      }
      if (mounted) Navigator.pop(context);
    } on StateError catch (e) {
      setState(() => _nameError = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogNotifierProvider).value;
    final groups = catalogState?.groups ?? const [];

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _nameError,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: groups
                      .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price', prefixText: 'PHP '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'Enter a valid price greater than 0';
                    return null;
                  },
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
