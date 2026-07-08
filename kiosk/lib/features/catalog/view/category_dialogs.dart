import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/text_box_form_field.dart';
import '../data/models/category.dart';
import '../state/catalog_categories_notifier.dart';

Future<CatalogCategory?> showSaveCategoryDialog(
  BuildContext context, {
  CatalogCategory? category,
}) {
  return showDialog<CatalogCategory>(
    context: context,
    builder: (context) => SaveCategoryDialog(category: category),
    barrierDismissible: false,
  );
}

class SaveCategoryDialog extends HookConsumerWidget {
  const SaveCategoryDialog({super.key, this.category});

  final CatalogCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: category?.name);
    final descriptionController = useTextEditingController(text: category?.description);
    final isActive = useState(category?.isActive ?? true);

    final saveAction = CatalogCategoriesNotifier.saveAction;
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
            width: r.value(kiosk: 560.0, tablet: 480.0, phone: double.infinity),
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
                  category != null ? 'Edit Category' : 'Add Category',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextBoxFormField(
                  controller: nameController,
                  label: 'Name',
                  hint: 'Enter category name',
                  maxLines: 1,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: Validate(rules: [isRequired()]).call,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                TextBoxFormField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Enter category description (optional)',
                  maxLines: 3,
                  maxLength: 500,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                        fontWeight: FontWeight.w500,
                        color: POSColors.textPrimary,
                      ),
                    ),
                    Switch(
                      value: isActive.value,
                      onChanged: (v) => isActive.value = v,
                      activeThumbColor: ColorSet.primary,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Button.outlined(
                      foregroundColor: ColorSet.text,
                      onPressed: () => Navigator.of(context).pop(),
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
                      ),
                    ),
                    Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
                    const Spacer(),
                    Button(
                      onPressed: saveStatus is! MutationPending
                          ? () {
                              if (!formKey.currentState!.validate()) return;
                              final updated = (category ?? CatalogCategory.draft()).copyWith(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                                isActive: isActive.value,
                              );
                              saveAction.run(ref, (txn) async {
                                return txn.get(catalogCategoriesProvider.notifier).save(updated);
                              }).ignore();
                            }
                          : null,
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      label: Text(
                        saveStatus is MutationPending
                            ? 'Saving...'
                            : (category != null ? 'Update' : 'Save'),
                        style: TextStyle(
                          fontSize: r.value(kiosk: 14, tablet: 14, phone: 12),
                        ),
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
