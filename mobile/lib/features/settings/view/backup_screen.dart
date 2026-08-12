import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/backup_providers.dart';
import 'restore_backup_dialog.dart';

class BackupScreen extends HookConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastBackupAt = ref.watch(lastBackupAtProvider);
    final isWorking = useState(false);

    Future<void> backUpNow() async {
      isWorking.value = true;
      try {
        final db = ref.read(databaseProvider);
        await BackupService.createBackup(db);
        ref.invalidate(lastBackupAtProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup created successfully.')));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      } finally {
        isWorking.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          lastBackupAt.when(
            data: (at) => Text(
              at == null
                  ? 'No backup has been made yet.'
                  : 'Last backup: ${DateFormat.yMMMd().add_jm().format(at)}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Gap(AppSpacing.md),
          _ActionTile(
            icon: Icons.backup_rounded,
            title: 'Back Up Now',
            subtitle: 'Create a backup and save it to Downloads',
            enabled: !isWorking.value,
            loading: isWorking.value,
            onTap: backUpNow,
          ),
          const Gap(AppSpacing.sm),
          _ActionTile(
            icon: Icons.restore_rounded,
            title: 'Restore Data',
            subtitle: 'Replace all data on this device from a backup file',
            enabled: true,
            loading: false,
            onTap: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const RestoreBackupDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: AppTextStyles.headingSm),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
