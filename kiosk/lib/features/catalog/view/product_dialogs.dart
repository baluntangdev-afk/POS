import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/image_picker_form_field.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../entities/product.dart';
import '../state/products_notifier.dart';

Future<Product?> showSaveProductDialog(BuildContext context, {Product? product}) {
  return showDialog<Product>(
    context: context,
    builder: (context) => SaveProductDialog(product: product),
    barrierDismissible: false,
  );
}

class SaveProductDialog extends HookConsumerWidget {
  const SaveProductDialog({super.key, this.product});

  final Product? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: product?.name);
    final descriptionController = useTextEditingController(text: product?.description);
    final imageController = useImagePickerController(product?.image);

    final saveAction = ProductsNotifier.saveAction;
    final saveStatus = ref.watch(saveAction);

    ref.listen(saveAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }

      if (next case MutationSuccess(
        :final value,
      ) when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

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
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Container(
            width: context.responsive.value(kiosk: 600, tablet: 600, phone: double.infinity),
            padding: EdgeInsetsGeometry.symmetric(
              horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
              children: [
                Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                Text(
                  product != null ? 'Update Product' : 'Add Product',
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 36, tablet: 28, phone: 20),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextBoxFormField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter product name',
                  maxLines: 1,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                TextBoxFormField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Enter product description',
                  maxLines: 3,
                  maxLength: 255,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                ImagePickerFormField(
                  controller: imageController,
                  height: context.responsive.value(kiosk: 200, tablet: 160, phone: 120),
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
                      ),
                    ),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
                    Button(
                      onPressed:
                          saveStatus is! MutationPending
                              ? () async {
                                if (!formKey.currentState!.validate()) return;

                                final newProduct = (product ?? Product.draft()).copyWith(
                                  name: nameController.text.trim(),
                                  description: descriptionController.text.trim(),
                                  image: imageController.value ?? Uint8List(0),
                                );

                                saveAction.run(ref, (txn) async {
                                  return txn.get(productsProvider.notifier).save(newProduct);
                                }).ignore();
                              }
                              : null,
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Text(
                        saveStatus is MutationPending
                            ? 'Saving...'
                            : (product != null ? 'Update' : 'Save'),
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showDeleteProductDialog(BuildContext context, Product product) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DeleteProductDialog(product: product),
  );
}

class DeleteProductDialog extends ConsumerWidget {
  const DeleteProductDialog({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteAction = ProductsNotifier.deleteAction;
    final deleteStatus = ref.watch(deleteAction);

    ref.listen(deleteAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }

      if (next case MutationSuccess(
        :final value,
      ) when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(value);
      }
    });

    return AlertDialog(
      title: const Text('Delete Product'),
      content: Text('Are you sure you want to delete ${product.name}?'),
      actions: [
        Button.outlined(
          foregroundColor: ColorSet.text,
          onPressed: () {
            Navigator.of(context).pop();
          },
          label: Text(
            'Cancel',
            style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
          ),
        ),
        Button(
          onPressed:
              deleteStatus is! MutationPending
                  ? () async {
                    deleteAction.run(ref, (txn) async {
                      return txn.get(productsProvider.notifier).delete(product);
                    }).ignore();
                  }
                  : null,
          foregroundColor: ColorSet.background,
          backgroundColor: ColorSet.danger,
          label: Text(
            deleteStatus is MutationPending ? 'Deleting...' : 'Delete',
            style: TextStyle(fontSize: context.responsive.value(kiosk: 14, tablet: 14, phone: 12)),
          ),
        ),
      ],
    );
  }
}
