import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/rules/min_value.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/image_picker_form_field.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/pos_loading_overlay.dart';
import '../../../widgets/text_box_form_field.dart';
import '../data/catalog_repository.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../state/catalog_categories_notifier.dart';
import '../state/catalog_products_notifier.dart';

Future<CatalogProduct?> showSaveProductDialog(BuildContext context, {CatalogProduct? product}) {
  return showDialog<CatalogProduct>(
    context: context,
    barrierDismissible: true,
    builder: (context) => SaveProductDialog(product: product),
  );
}

class SaveProductDialog extends HookConsumerWidget {
  const SaveProductDialog({super.key, this.product});

  final CatalogProduct? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: product?.name);
    final categoryId = useState<String?>(product?.category?.id);
    final imageController = useImagePickerController();

    final variantsFuture = useMemoized(
      () => product != null
          ? ref.read(catalogRepositoryProvider).fetchProductVariants(product!.id)
          : Future.value(const <CatalogProductVariant>[]),
      [product?.id],
    );
    final variantsSnapshot = useFuture(variantsFuture);
    final isLoadingVariants = product != null && !variantsSnapshot.hasData;

    final variantRows = useState<List<_VariantRow>>(
      product == null ? [_VariantRow.blank(isDefault: true)] : const [],
    );
    final variantsInitialized = useRef(false);

    useEffect(() {
      if (variantsSnapshot.hasData && !variantsInitialized.value) {
        variantsInitialized.value = true;
        final loaded = variantsSnapshot.data!;
        variantRows.value = loaded.isEmpty
            ? [_VariantRow.blank(isDefault: true)]
            : loaded.map(_VariantRow.fromVariant).toList();
      }
      return null;
    }, [variantsSnapshot.hasData]);

    useEffect(() {
      return () {
        for (final row in variantRows.value) {
          row.dispose();
        }
      };
    }, const []);

    final categoriesAsync = ref.watch(catalogCategoriesProvider);
    final categories = categoriesAsync.value ?? const <CatalogCategory>[];

    final saveAction = CatalogProductsNotifier.saveAction;
    final saveStatus = ref.watch(saveAction);

    ref.listen(saveAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)
          when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

    final r = context.responsive;

    if (isLoadingVariants) {
      return Dialog(
        backgroundColor: ColorSet.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.value(kiosk: 32, tablet: 24, phone: 16)),
        ),
        child: Container(
          width: r.value(kiosk: 600.0, tablet: 500.0, phone: double.infinity),
          padding: EdgeInsets.all(r.value(kiosk: 56.0, tablet: 48.0, phone: 40.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // POSLoadingIndicator(size: r.value(kiosk: 56, tablet: 48, phone: 44)),
              Gap(r.value(kiosk: 20, tablet: 16, phone: 12)),
              Text(
                'Loading variants…',
                style: TextStyle(
                  fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                  fontWeight: FontWeight.w500,
                  color: POSColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 32, tablet: 24, phone: 16)),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: r.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: r.value(kiosk: 32, tablet: 24, phone: 16),
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: r.value(kiosk: 600.0, tablet: 500.0, phone: double.infinity),
            padding: EdgeInsets.symmetric(
              horizontal: r.value(kiosk: 32, tablet: 24, phone: 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: r.value(kiosk: 16, tablet: 12, phone: 8),
              children: [
                Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                Text(
                  product != null ? 'Edit Product' : 'Add Product',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextBoxFormField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter product name',
                  maxLines: 1,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                ),
                _CategoryField(
                  categories: categories,
                  value: categoryId.value,
                  onChanged: (value) => categoryId.value = value,
                ),
                _VariantsSection(rows: variantRows),
                if (product != null && product!.imageUrl != null && product!.imageUrl!.isNotEmpty)
                  _CurrentImageThumbnail(imageUrl: product!.imageUrl!),
                ImagePickerFormField(
                  controller: imageController,
                  label: product != null && product!.imageUrl != null && product!.imageUrl!.isNotEmpty
                      ? 'Replace Image'
                      : 'Image (optional)',
                  height: r.value(kiosk: 180, tablet: 150, phone: 110),
                  style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () => Navigator.of(context).pop(),
                      label: Text(
                        'Cancel',
                        style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                      ),
                    ),
                    Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Button(
                      onPressed: saveStatus is! MutationPending
                          ? () {
                              if (!formKey.currentState!.validate()) return;

                              final variantError = _validateVariantRows(variantRows.value);
                              if (variantError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(variantError),
                                    backgroundColor: ColorSet.danger,
                                  ),
                                );
                                return;
                              }

                              final selectedCategory = categories.firstWhere(
                                (c) => c.id == categoryId.value,
                              );
                              final draft = (product ?? CatalogProduct.draft()).copyWith(
                                name: nameController.text.trim(),
                                category: CatalogCategoryRef(
                                  id: selectedCategory.id,
                                  name: selectedCategory.name,
                                ),
                              );
                              final variants = variantRows.value
                                  .map(
                                    (row) => CatalogProductVariant(
                                      id: row.id,
                                      name: row.nameController.text.trim(),
                                      price: double.parse(row.priceController.text.trim()),
                                      isDefault: row.isDefault,
                                    ),
                                  )
                                  .toList();

                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogProductsProvider.notifier).save(
                                      draft,
                                      variants,
                                      imageBytes: imageController.value,
                                    );
                              }).ignore();
                            }
                          : null,
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Text(
                        saveStatus is MutationPending
                            ? 'Saving...'
                            : (product != null ? 'Update' : 'Save'),
                        style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
                      ),
                    ),
                  ],
                ),
                Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.categories, required this.value, required this.onChanged});

  final List<CatalogCategory> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        const Gap(4),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: const Text('Select category'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: const BorderSide(color: POSColors.borderDefault),
            ),
          ),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => (v == null || v.isEmpty) ? 'Please select a category.' : null,
        ),
      ],
    );
  }
}

class _CurrentImageThumbnail extends StatelessWidget {
  const _CurrentImageThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current image',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        const Gap(4),
        ClipRRect(
          borderRadius: BorderRadius.circular(POSRadius.md),
          child: Image.network(
            imageUrl,
            height: r.value(kiosk: 100, tablet: 90, phone: 70),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: r.value(kiosk: 100, tablet: 90, phone: 70),
              color: POSColors.surfaceSubtle,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_rounded, color: POSColors.iconSubtle),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantRow {
  _VariantRow({
    required this.id,
    required this.nameController,
    required this.priceController,
    required this.isDefault,
  }) : nameFocusNode = FocusNode();

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final FocusNode nameFocusNode;
  bool isDefault;

  factory _VariantRow.blank({required bool isDefault}) {
    return _VariantRow(
      id: '',
      nameController: TextEditingController(),
      priceController: TextEditingController(),
      isDefault: isDefault,
    );
  }

  factory _VariantRow.fromVariant(CatalogProductVariant variant) {
    return _VariantRow(
      id: variant.id,
      nameController: TextEditingController(text: variant.name),
      priceController: TextEditingController(text: variant.price.toStringAsFixed(2)),
      isDefault: variant.isDefault,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    nameFocusNode.dispose();
  }
}

String? _validateVariantRows(List<_VariantRow> rows) {
  if (rows.isEmpty) return 'Add at least one variant.';
  final seenNames = <String>[];
  for (final row in rows) {
    final name = row.nameController.text.trim();
    if (name.isEmpty) return 'Every variant needs a name.';
    if (seenNames.contains(name.toLowerCase())) {
      return 'Variant names must be unique ("$name" is repeated).';
    }
    seenNames.add(name.toLowerCase());

    final price = double.tryParse(row.priceController.text.trim());
    if (price == null || price < 0.01) {
      return 'Every variant needs a price of at least 0.01.';
    }
  }
  return null;
}

class _VariantsSection extends HookConsumerWidget {
  const _VariantsSection({required this.rows});

  final ValueNotifier<List<_VariantRow>> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final namesAsync = ref.watch(catalogVariantNamesProvider);
    final existingNames = namesAsync.value ?? const <String>[];

    void setDefault(_VariantRow target) {
      for (final row in rows.value) {
        row.isDefault = identical(row, target);
      }
      rows.value = [...rows.value];
    }

    void addRow() {
      rows.value = [...rows.value, _VariantRow.blank(isDefault: rows.value.isEmpty)];
    }

    void removeRow(_VariantRow row) {
      final wasDefault = row.isDefault;
      row.dispose();
      final updated = rows.value.where((r) => r != row).toList();
      if (wasDefault && updated.isNotEmpty) {
        updated.first.isDefault = true;
      }
      rows.value = updated;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variants',
          style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
        ),
        Text(
          'e.g. Regular, Venti',
          style: TextStyle(
            fontSize: r.value(kiosk: 12, tablet: 12, phone: 11),
            color: POSColors.textTertiary,
          ),
        ),
        const Gap(8),
        for (final row in rows.value) ...[
          _VariantRowField(
            row: row,
            existingNames: existingNames,
            onSetDefault: () => setDefault(row),
            onRemove: rows.value.length > 1 ? () => removeRow(row) : null,
          ),
          const Gap(8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Button.outlined(
            foregroundColor: ColorSet.primary,
            leading: const Icon(Icons.add, size: 18),
            onPressed: addRow,
            label: Text(
              'Add Variant',
              style: TextStyle(fontSize: r.value(kiosk: 13, tablet: 13, phone: 12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _VariantRowField extends StatelessWidget {
  const _VariantRowField({
    required this.row,
    required this.existingNames,
    required this.onSetDefault,
    required this.onRemove,
  });

  final _VariantRow row;
  final List<String> existingNames;
  final VoidCallback onSetDefault;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Autocomplete<String>(
            textEditingController: row.nameController,
            focusNode: row.nameFocusNode,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return existingNames;
              return existingNames.where(
                (name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (selection) => row.nameController.text = selection,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'e.g. Regular, Venti',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    borderSide: const BorderSide(color: POSColors.borderDefault),
                  ),
                ),
                validator: Validate(rules: [isRequired()]).call,
              );
            },
          ),
        ),
        const Gap(8),
        Expanded(
          flex: 2,
          child: TextBoxFormField(
            controller: row.priceController,
            hint: 'Price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: r.value(kiosk: 14, tablet: 14, phone: 12)),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Required.';
              final price = double.tryParse(trimmed);
              if (price == null) return 'Invalid number.';
              return Validate<double>(rules: [minValue(0.01)]).call(price);
            },
          ),
        ),
        const Gap(4),
        IconButton(
          onPressed: onSetDefault,
          icon: Icon(
            row.isDefault ? Icons.star_rounded : Icons.star_border_rounded,
            color: row.isDefault ? ColorSet.secondary : POSColors.iconSubtle,
          ),
          tooltip: 'Default variant',
        ),
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.close_rounded,
            color: onRemove != null ? ColorSet.danger : POSColors.textDisabled,
          ),
          tooltip: 'Remove variant',
        ),
      ],
    );
  }
}

Future<bool?> showDeleteProductDialog(BuildContext context, CatalogProduct product) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteProductDialog(product: product),
  );
}

class DeleteProductDialog extends ConsumerWidget {
  const DeleteProductDialog({super.key, required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteAction = CatalogProductsNotifier.deleteAction;
    final deleteStatus = ref.watch(deleteAction);

    ref.listen(deleteAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)
          when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

    final r = context.responsive;

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 24, tablet: 20, phone: 16)),
      ),
      child: Container(
        width: r.value<double>(kiosk: 440, tablet: 380, phone: double.infinity),
        padding: EdgeInsets.all(r.value(kiosk: 32.0, tablet: 24.0, phone: 20.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: r.value<double>(kiosk: 80, tablet: 64, phone: 56),
              height: r.value<double>(kiosk: 80, tablet: 64, phone: 56),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: ColorSet.danger,
                size: r.value<double>(kiosk: 40, tablet: 32, phone: 28),
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
            Text(
              'Delete Product',
              style: TextStyle(
                fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                fontWeight: FontWeight.w700,
                color: ColorSet.text,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 10, tablet: 8, phone: 6)),
            Text(
              'Are you sure you want to delete "${product.name}"?\nThis action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                color: ColorSet.text.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 28, tablet: 24, phone: 20)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: ColorSet.text.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w600,
                        color: ColorSet.text,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.value<double>(kiosk: 16, tablet: 12, phone: 8)),
                Expanded(
                  child: FilledButton(
                    onPressed: deleteStatus is! MutationPending
                        ? () {
                            deleteAction.run(ref, (txn) async {
                              return txn.get(catalogProductsProvider.notifier).delete(product.id);
                            }).ignore();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorSet.danger,
                      padding: EdgeInsets.symmetric(
                        vertical: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      deleteStatus is MutationPending ? 'Deleting...' : 'Delete',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w600,
                        color: ColorSet.light,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
