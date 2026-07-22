import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/csv/csv_importer.dart';
import '../../../core/csv/modifiers_csv_importer.dart';
import '../../../core/csv/products_csv_importer.dart';
import '../../../core/csv/store_info_csv_importer.dart';
import '../../../core/csv/users_csv_importer.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../catalog/state/catalog_notifier.dart';

class CsvImportScreen extends HookConsumerWidget {
  const CsvImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    final importers = useMemoized(
      () => [
        _ImporterConfig(
          title: 'Products',
          subtitle: 'Columns: category_name, name, price, is_available, image_url, sort_order',
          icon: Icons.inventory_2_outlined,
          importer: ProductsCsvImporter(db),
        ),
        _ImporterConfig(
          title: 'Modifiers',
          subtitle:
              'Columns: product_name, group_name, is_required, max_selections, option_name, additional_price',
          icon: Icons.tune_rounded,
          importer: ModifiersCsvImporter(db),
        ),
        _ImporterConfig(
          title: 'Users',
          subtitle: 'Columns: name, role (admin/cashier), pin (6-digit)',
          icon: Icons.people_outline_rounded,
          importer: UsersCsvImporter(db),
        ),
        _ImporterConfig(
          title: 'Store Info',
          subtitle: 'Columns: key, value  (keys: store_name, address, tax_rate, currency, receipt_footer)',
          icon: Icons.store_outlined,
          importer: StoreInfoCsvImporter(db),
        ),
      ],
      [db],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Import CSV')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: importers.length,
        separatorBuilder: (context, index) => const Gap(AppSpacing.md),
        itemBuilder: (_, i) => _ImportCard(config: importers[i], ref: ref),
      ),
    );
  }
}

class _ImporterConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final CsvImporter importer;
  const _ImporterConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.importer,
  });
}

class _ImportCard extends HookConsumerWidget {
  final _ImporterConfig config;
  final WidgetRef ref;
  const _ImportCard({required this.config, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = useState<ImportResult?>(null);
    final isLoading = useState(false);
    final fileName = useState<String?>(null);
    final showErrors = useState(false);

    Future<void> pickAndImport() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      if (picked == null || picked.files.isEmpty) return;

      final path = picked.files.first.path;
      if (path == null) return;

      fileName.value = picked.files.first.name;
      isLoading.value = true;
      result.value = null;
      showErrors.value = false;

      try {
        final importResult = await config.importer.importFile(File(path));
        result.value = importResult;
        // Refresh catalog if products/modifiers were imported
        if (config.title == 'Products' || config.title == 'Modifiers') {
          ref.invalidate(catalogNotifierProvider);
        }
      } catch (e) {
        result.value = ImportResult(
          successCount: 0,
          skippedCount: 0,
          errors: [CsvRowError(0, e.toString())],
        );
      } finally {
        isLoading.value = false;
      }
    }

    final r = result.value;
    final hasResult = r != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(config.icon, color: AppColors.primary, size: 24),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.title, style: AppTextStyles.headingSm),
                      const Gap(2),
                      Text(
                        config.subtitle,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Result banner ─────────────────────────────────────────────
          if (hasResult) ...[
            const Divider(height: 1, color: AppColors.divider),
            _ResultBanner(result: r, fileName: fileName.value),
            if (r.hasErrors) ...[
              InkWell(
                onTap: () => showErrors.value = !showErrors.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        showErrors.value
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const Gap(4),
                      Text(
                        '${r.errors.length} error${r.errors.length == 1 ? '' : 's'}',
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
              if (showErrors.value)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: r.errors
                        .take(20)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Row ${e.row}: ${e.message}',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ],

          // ── Action button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading.value ? null : pickAndImport,
                icon: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(isLoading.value ? 'Importing…' : 'Choose CSV file'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.touchPreferred),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final ImportResult result;
  final String? fileName;

  const _ResultBanner({required this.result, this.fileName});

  @override
  Widget build(BuildContext context) {
    final color = result.hasErrors
        ? (result.successCount > 0 ? AppColors.warning : AppColors.error)
        : AppColors.success;
    final icon = result.hasErrors
        ? (result.successCount > 0 ? Icons.warning_amber_rounded : Icons.cancel_rounded)
        : Icons.check_circle_rounded;

    return Container(
      color: color.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fileName != null)
                  Text(fileName!, style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
                const Gap(2),
                Text(
                  '${result.successCount} imported'
                  '${result.skippedCount > 0 ? ' · ${result.skippedCount} skipped' : ''}'
                  '${result.errors.isNotEmpty ? ' · ${result.errors.length} failed' : ''}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
