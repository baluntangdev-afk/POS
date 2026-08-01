import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../data/models/import_products_csv_result.dart';
import '../state/inventory_products_notifier.dart';

const _templateHeader =
    'Category,Category Description,Product Name,Product Description,Product Base Price,Variant Name,Variant Price,Product Image URL\n';

Future<void> showImportProductsCsvDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const ImportProductsCsvDialog(),
    barrierDismissible: false,
  );
}

class ImportProductsCsvDialog extends HookConsumerWidget {
  const ImportProductsCsvDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickedFileName = useState<String?>(null);
    final pickedFileBytes = useState<Uint8List?>(null);
    final mode = useState<String>('upsert');

    final importAction = InventoryProductsNotifier.importCsvAction;
    final importStatus = ref.watch(importAction);
    final isImporting = importStatus is MutationPending;

    ref.listen(importAction, (prev, next) async {
      if (next case MutationError(:final error)) {
        return showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)
          when context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _showResultDialog(context, value, mode.value);
      }
    });

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;
      pickedFileName.value = file!.name;
      pickedFileBytes.value = file.bytes;
    }

    Future<void> downloadTemplate() async {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV template',
        fileName: 'products-template.csv',
      );
      if (path == null) return;
      await File(path).writeAsBytes(utf8.encode(_templateHeader));
    }

    void runImport() {
      importAction.run(ref, (txn) async {
        return txn.get(inventoryProductsProvider.notifier).importCsv(
              fileBytes: pickedFileBytes.value!,
              fileName: pickedFileName.value!,
              mode: mode.value,
            );
      }).ignore();
    }

    void onImportPressed() {
      if (mode.value == 'replace') {
        showMessageDialog(
          context,
          title: 'Replace Entire Menu?',
          message:
              'This will remove every category, product, and variant not '
              'present in the imported file. This cannot be undone from '
              'within the app.',
          type: DialogType.warning,
          primaryButtonText: 'Yes, Replace',
          secondaryButtonText: 'Cancel',
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            runImport();
          },
          onSecondaryPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        );
      } else {
        runImport();
      }
    }

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
      child: SingleChildScrollView(
        child: Container(
          width: r.value(kiosk: 560.0, tablet: 480.0, phone: double.infinity),
          padding: EdgeInsets.all(r.value(kiosk: 32, tablet: 24, phone: 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: r.value(kiosk: 16, tablet: 12, phone: 8),
            children: [
              Text(
                'Import Products CSV',
                style: TextStyle(
                  fontSize: r.value(kiosk: 28.0, tablet: 22.0, phone: 18.0),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Expected header: Category, Category Description, Product Name, '
                'Product Description, Product Base Price, Variant Name, Variant '
                'Price, and optionally Product Image URL.',
                style: TextStyle(
                  fontSize: r.value(kiosk: 13, tablet: 12, phone: 11),
                  color: POSColors.textSecondary,
                ),
              ),
              Button.outlined(
                foregroundColor: ColorSet.primary,
                leading: const Icon(Icons.download_rounded),
                onPressed: downloadTemplate,
                label: const Text('Download template'),
              ),
              Gap(r.value(kiosk: 4, tablet: 4, phone: 4)),
              Text(
                'Import mode',
                style: TextStyle(
                  fontSize: r.value(kiosk: 14, tablet: 13, phone: 12),
                  fontWeight: FontWeight.w600,
                  color: POSColors.textPrimary,
                ),
              ),
              _ModeOption(
                title: 'Add & Update (Upsert)',
                subtitle:
                    'Adds new products and updates existing ones by name. '
                    'Nothing already in your menu is removed.',
                selected: mode.value == 'upsert',
                onTap: () => mode.value = 'upsert',
              ),
              _ModeOption(
                title: 'Replace Entire Menu',
                subtitle:
                    'The file becomes the full menu — anything not in it is removed.',
                selected: mode.value == 'replace',
                onTap: () => mode.value = 'replace',
              ),
              if (mode.value == 'replace')
                Container(
                  padding: EdgeInsets.all(r.value(kiosk: 12, tablet: 10, phone: 8)),
                  decoration: BoxDecoration(
                    color: ColorSet.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    border: Border.all(color: ColorSet.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_rounded, color: ColorSet.danger, size: 20),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'This will remove every category, product, and variant '
                          'not present in the imported file. This cannot be undone '
                          'from within the app. Make sure your CSV contains your '
                          'complete menu before continuing.',
                          style: TextStyle(
                            fontSize: r.value(kiosk: 12, tablet: 11, phone: 10),
                            color: ColorSet.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Gap(r.value(kiosk: 4, tablet: 4, phone: 4)),
              Button.outlined(
                foregroundColor: ColorSet.text,
                leading: const Icon(Icons.attach_file_rounded),
                onPressed: pickFile,
                label: Text(pickedFileName.value ?? 'Choose CSV file'),
              ),
              Gap(r.value(kiosk: 8, tablet: 8, phone: 8)),
              Row(
                children: [
                  Button.outlined(
                    foregroundColor: ColorSet.text,
                    onPressed: isImporting ? null : () => Navigator.of(context).pop(),
                    label: const Text('Cancel'),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Button(
                      foregroundColor: ColorSet.background,
                      backgroundColor: ColorSet.secondary,
                      onPressed:
                          (!isImporting && pickedFileBytes.value != null) ? onImportPressed : null,
                      label: Text(isImporting ? 'Importing...' : 'Import'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(POSRadius.md),
      child: Container(
        padding: EdgeInsets.all(r.value(kiosk: 12, tablet: 10, phone: 8)),
        decoration: BoxDecoration(
          color: selected ? ColorSet.primary.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(POSRadius.md),
          border: Border.all(
            color: selected ? ColorSet.primary : POSColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? ColorSet.primary : POSColors.textDisabled,
              size: 20,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: r.value(kiosk: 14, tablet: 13, phone: 12),
                      fontWeight: FontWeight.w600,
                      color: POSColors.textPrimary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: r.value(kiosk: 12, tablet: 11, phone: 10),
                      color: POSColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showResultDialog(BuildContext context, ImportProductsCsvResult result, String mode) {
  final categoriesRemoved = mode == 'replace' ? ', ${result.categoriesDeleted} removed' : '';
  final productsRemoved = mode == 'replace' ? ', ${result.productsDeleted} removed' : '';
  final variantsRemoved = mode == 'replace' ? ', ${result.variantsDeleted} removed' : '';
  final lines = [
    'Categories: ${result.categoriesInserted} added, ${result.categoriesUpdated} updated$categoriesRemoved',
    'Products: ${result.productsInserted} added, ${result.productsUpdated} updated$productsRemoved',
    'Variants: ${result.variantsInserted} added, ${result.variantsUpdated} updated$variantsRemoved',
  ];
  showMessageDialog(
    context,
    title: 'Import Complete',
    message: lines.join('\n'),
    type: DialogType.success,
  );
}
