import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/csv/products_csv_importer.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../inventory/state/inventory_notifier.dart';

/// Products CSV import flow — mirrors the kiosk (Windows) app's "Import
/// Products CSV" dialog: expected-header hint, a copyable template row, an
/// Add & Update vs Replace Entire Menu mode choice (with a confirmation
/// warning before replacing), a file picker, and a results summary dialog.
Future<void> showImportProductsCsvDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ImportProductsCsvDialog(),
  );
}

class ImportProductsCsvDialog extends HookConsumerWidget {
  const ImportProductsCsvDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickedFileName = useState<String?>(null);
    final pickedFilePath = useState<String?>(null);
    final mode = useState(ProductsCsvImportMode.upsert);
    final isImporting = useState(false);

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      final file = result?.files.single;
      if (file?.path == null) return;
      pickedFileName.value = file!.name;
      pickedFilePath.value = file.path;
    }

    Future<void> copyTemplate() async {
      await Clipboard.setData(const ClipboardData(text: kProductsCsvHeader));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template header copied to clipboard')),
      );
    }

    Future<void> runImport() async {
      isImporting.value = true;
      try {
        final db = ref.read(databaseProvider);
        final importer = ProductsCsvImporter(db);
        final summary = await importer.importCsv(
          File(pickedFilePath.value!),
          mode: mode.value,
        );
        ref.invalidate(inventoryNotifierProvider);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        _showResultDialog(context, summary, mode.value);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      } finally {
        isImporting.value = false;
      }
    }

    Future<void> onImportPressed() async {
      if (mode.value == ProductsCsvImportMode.replace) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace Entire Menu?'),
            content: const Text(
              'This will delete every category, product, and variant not '
              'present in the imported file (items with past sales are kept '
              'but disabled instead, so reports stay accurate). This cannot '
              'be undone from within the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Replace'),
              ),
            ],
          ),
        );
        if (confirmed == true) await runImport();
      } else {
        await runImport();
      }
    }

    return AlertDialog(
      title: const Text('Import Products CSV'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expected header: Category, Category Description, Product Name, '
                'Product Description, Product Base Price, Variant Name, Variant '
                'Price, and optionally Product Image URL. Same format as the '
                'kiosk app.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              const Gap(AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: copyTemplate,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy template header'),
              ),
              const Gap(AppSpacing.md),
              Text('Import mode', style: AppTextStyles.labelLg),
              const Gap(AppSpacing.xs),
              _ModeOption(
                title: 'Add & Update (Upsert)',
                subtitle: 'Adds new products and updates existing ones by name. '
                    'Nothing already in your menu is removed.',
                selected: mode.value == ProductsCsvImportMode.upsert,
                onTap: () => mode.value = ProductsCsvImportMode.upsert,
              ),
              const Gap(AppSpacing.sm),
              _ModeOption(
                title: 'Replace Entire Menu',
                subtitle: 'The file becomes the full menu — anything not in it '
                    'is deleted.',
                selected: mode.value == ProductsCsvImportMode.replace,
                onTap: () => mode.value = ProductsCsvImportMode.replace,
              ),
              if (mode.value == ProductsCsvImportMode.replace) ...[
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                      const Gap(AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This will delete every category, product, and '
                          'variant not present in the imported file. Make sure '
                          'your CSV contains your complete menu before continuing.',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text(pickedFileName.value ?? 'Choose CSV file'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isImporting.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (!isImporting.value && pickedFilePath.value != null) ? onImportPressed : null,
          child: isImporting.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Import'),
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textDisabled,
              size: 20,
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLg),
                  const Gap(2),
                  Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showResultDialog(
  BuildContext context,
  ProductsCsvImportSummary result,
  ProductsCsvImportMode mode,
) {
  final isReplace = mode == ProductsCsvImportMode.replace;
  final categoriesRemoved = isReplace ? ', ${result.categoriesRemoved} deleted' : '';
  final productsRemoved = isReplace ? ', ${result.productsRemoved} deleted' : '';
  final variantsRemoved = isReplace ? ', ${result.variantsRemoved} deleted' : '';
  final lines = [
    'Categories: ${result.categoriesInserted} added, ${result.categoriesUpdated} updated$categoriesRemoved',
    'Products: ${result.productsInserted} added, ${result.productsUpdated} updated$productsRemoved',
    'Variants: ${result.variantsInserted} added, ${result.variantsUpdated} updated$variantsRemoved',
    if (isReplace && result.productsKeptForHistory > 0)
      '${result.productsKeptForHistory} product${result.productsKeptForHistory == 1 ? '' : 's'} '
          "couldn't be deleted (past sales) — disabled instead",
    if (result.hasErrors) '\n${result.errors.length} row error${result.errors.length == 1 ? '' : 's'}',
  ];

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(result.hasErrors ? 'Import Completed With Errors' : 'Import Complete'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lines.join('\n')),
              if (result.hasErrors) ...[
                const Gap(AppSpacing.sm),
                ...result.errors.take(20).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Row ${e.row}: ${e.message}',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
