import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/form_sheet_scaffold.dart';
import '../../../core/widgets/popup_menu_form_field.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';
import '../state/modifier_groups_notifier.dart';

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

  /// Opens the form as a bottom sheet anchored to the keyboard, rather than
  /// a centered dialog sized for desktop widths.
  static Future<void> show(BuildContext context, {InventoryProduct? existing, int? groupId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormDialog(existing: existing, groupId: groupId),
    );
  }

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
  Set<int> _selectedModifierGroupIds = {};
  Set<int> _originalModifierGroupIds = {};
  bool _modifierGroupsLoaded = false;

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
      _loadModifierGroups();
    } else {
      _variants = [_VariantRow.blank(isDefault: true)];
      _variantsLoaded = true;
      _modifierGroupsLoaded = true;
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

  Future<void> _loadModifierGroups() async {
    final attached = await ref.read(attachedModifierGroupsProvider(widget.existing!.id).future);
    if (!mounted) return;
    setState(() {
      _selectedModifierGroupIds = attached.map((g) => g.id).toSet();
      _originalModifierGroupIds = Set.of(_selectedModifierGroupIds);
      _modifierGroupsLoaded = true;
    });
  }

  void _toggleModifierGroup(int groupId, bool selected) {
    setState(() {
      if (selected) {
        _selectedModifierGroupIds.add(groupId);
      } else {
        _selectedModifierGroupIds.remove(groupId);
      }
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

      final modifierActions = ref.read(productModifierGroupActionsProvider(productId));
      if (_isEditing) {
        final toAttach = _selectedModifierGroupIds.difference(_originalModifierGroupIds);
        final toDetach = _originalModifierGroupIds.difference(_selectedModifierGroupIds);
        for (final id in toAttach) {
          await modifierActions.attach(id);
        }
        for (final id in toDetach) {
          await modifierActions.detach(id);
        }
      } else {
        for (final id in _selectedModifierGroupIds) {
          await modifierActions.attach(id);
        }
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
    final inventoryState = ref.watch(inventoryNotifierProvider).value;
    final groups = inventoryState?.groups ?? const [];
    final modifierGroupsAsync = ref.watch(allModifierGroupsProvider);

    return FormSheetScaffold(
      title: _isEditing ? 'Edit Product' : 'Add Product',
      confirmLabel: _isEditing ? 'Save' : 'Add',
      isSaving: _isSaving,
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              icon: Icons.label_outline_rounded,
              label: 'Basics',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoPicker(
                    imageUrl: _imageUrl,
                    onTap: _pickImage,
                    onRemove: _removeImage,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            errorText: _nameError,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          onChanged: (_) {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                        ),
                        const Gap(AppSpacing.sm),
                        PopupMenuFormField<int>(
                          initialValue: _selectedGroupId,
                          decoration: const InputDecoration(labelText: 'Category', isDense: true),
                          items: groups
                              .map((g) => PopupMenuFormFieldItem(value: g.id, child: Text(g.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGroupId = v),
                          validator: (v) => v == null ? 'Category is required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.md),
            _SectionCard(
              icon: Icons.layers_outlined,
              label: 'Variants',
              trailing: TextButton.icon(
                onPressed: _addVariant,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Variant'),
              ),
              child: Column(
                children: [
                  if (_variantsError != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_variantsError!,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                    ),
                    const Gap(AppSpacing.sm),
                  ],
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
            const Gap(AppSpacing.md),
            _SectionCard(
              icon: Icons.tune_rounded,
              label: 'Modifier Groups',
              subtitle: 'Select which modifier groups apply to this product.',
              child: _ModifierGroupsSection(
                async: modifierGroupsAsync,
                loaded: _modifierGroupsLoaded,
                selectedIds: _selectedModifierGroupIds,
                onToggle: _toggleModifierGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card shell shared by every section of the product form: a tinted icon,
/// a label, an optional trailing action on the header row, and an optional
/// subtitle beneath it.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(label, style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const Gap(2),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(subtitle!, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            ),
          ],
          const Gap(AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Tappable photo picker: the thumbnail itself opens the file picker, an
/// edit-pencil badge signals it's editable, and a clear badge (shown only
/// once an image is set) removes it — an avatar-picker pattern instead of
/// a small square next to a row of text buttons.
class _PhotoPicker extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoPicker({required this.imageUrl, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Material(
                color: AppColors.surfaceVariant,
                child: InkWell(
                  onTap: onTap,
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: AppColors.textPrimary),
                ),
              ),
            ),
          Positioned(
            bottom: -4,
            right: -4,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.card,
                ),
                child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
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

class _ModifierGroupsSection extends StatelessWidget {
  final AsyncValue<List<ModifierGroupWithOptions>> async;
  final bool loaded;
  final Set<int> selectedIds;
  final void Function(int groupId, bool selected) onToggle;

  const _ModifierGroupsSection({
    required this.async,
    required this.loaded,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Failed to load modifier groups',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
      ),
      data: (allGroups) {
        if (!loaded) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final activeGroups = allGroups.where((g) => g.group.isActive).toList();
        if (activeGroups.isEmpty) {
          return Text(
            'No modifier groups yet. Create one from the Modifiers tab.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
          );
        }
        return Column(
          children: [
            for (final entry in activeGroups)
              _ModifierGroupRow(
                entry: entry,
                selected: selectedIds.contains(entry.group.id),
                onToggle: (v) => onToggle(entry.group.id, v),
              ),
          ],
        );
      },
    );
  }
}

/// A single selectable modifier-group row: tints teal and gains a border
/// when selected, like a filter chip, instead of a bare checkbox list item.
class _ModifierGroupRow extends StatelessWidget {
  final ModifierGroupWithOptions entry;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _ModifierGroupRow({required this.entry, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final group = entry.group;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => onToggle(!selected),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${group.isRequired ? 'Required' : 'Optional'} · '
                        'Max ${group.maxSelections} · ${entry.options.length} option(s)',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Checkbox(value: selected, onChanged: (v) => onToggle(v ?? false)),
              ],
            ),
          ),
        ),
      ),
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
    // Two rows instead of one: name + price + status actions never fit side
    // by side at phone width, so fields and actions get their own line
    // inside a card that groups them visually. A left accent rail + pill
    // marks the default variant instead of a star icon/text toggle.
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: row.isDefault
              ? AppColors.secondaryDark.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              color: row.isDefault ? AppColors.secondaryDark : Colors.transparent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: row.nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Variant name',
                              isDense: true,
                            ),
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: row.priceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'PHP ',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                          ),
                        ),
                        if (row.isDefault) ...[
                          const Gap(AppSpacing.xs),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryDark.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!row.isDefault)
                          TextButton(
                            onPressed: row.isActive ? onSetDefault : null,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Set as default', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
                          )
                        else
                          const SizedBox.shrink(),
                        if (isNew)
                          TextButton.icon(
                            onPressed: onRemove,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                            label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Active', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(value: row.isActive, onChanged: onToggleActive),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

