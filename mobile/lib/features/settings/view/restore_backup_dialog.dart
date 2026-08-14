import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/backup/backup_archive_service.dart';
import '../../../core/services/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../inventory/state/inventory_notifier.dart';
import '../../inventory/state/modifier_groups_notifier.dart';
import '../../users/state/users_notifier.dart';
import '../state/store_info_notifier.dart';

/// Restoring only requires being logged in as admin/supervisor to reach
/// this screen (already enforced by the router).
class RestoreBackupDialog extends HookConsumerWidget {
  const RestoreBackupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickedFileName = useState<String?>(null);
    final pickedFilePath = useState<String?>(null);
    final isRestoring = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final file = result?.files.single;
      if (file?.path == null) return;
      pickedFileName.value = file!.name;
      pickedFilePath.value = file.path;
      errorMessage.value = null;
    }

    Future<void> onRestorePressed() async {
      if (pickedFilePath.value == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace All Data?'),
          content: const Text(
            'This will replace all data currently on this device with the '
            'contents of this backup. A safety backup of the current data '
            'will be made first. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, Restore'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      isRestoring.value = true;
      errorMessage.value = null;
      try {
        final db = ref.read(databaseProvider);
        await BackupService.restoreBackup(
          db,
          zipFile: File(pickedFilePath.value!),
        );

        // restoreBackup writes directly to SQLite via raw statements, which
        // Riverpod has no visibility into — every provider caching data from
        // a restored table must be invalidated explicitly, or screens (and
        // the dashboard's setup prompts) keep showing whatever they last
        // resolved to, pre-restore.
        ref.invalidate(storeInfoProvider);
        ref.invalidate(paymentMethodsProvider);
        ref.invalidate(usersProvider);
        ref.invalidate(inventoryNotifierProvider);
        ref.invalidate(allModifierGroupsProvider);

        if (!context.mounted) return;
        Navigator.of(context).pop();
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text(
              'Data has been restored.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } on BackupArchiveException catch (e) {
        if (context.mounted) errorMessage.value = e.message;
      } catch (e) {
        if (context.mounted) errorMessage.value = 'Restore failed: $e';
      } finally {
        // The success path already popped this dialog (and awaited another)
        // before reaching here, so the widget — and this useState hook — may
        // already be disposed; writing to it then throws.
        if (context.mounted) isRestoring.value = false;
      }
    }

    return AlertDialog(
      title: const Text('Restore Data'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a backup .zip file to restore it onto this device.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              const Gap(AppSpacing.md),
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text(pickedFileName.value ?? 'Choose backup file'),
              ),
              if (errorMessage.value != null) ...[
                const Gap(AppSpacing.sm),
                Text(
                  errorMessage.value!,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isRestoring.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (!isRestoring.value && pickedFilePath.value != null)
              ? onRestorePressed
              : null,
          child: isRestoring.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Restore'),
        ),
      ],
    );
  }
}
