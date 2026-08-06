import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdminOrSupervisor ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },

      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: Icon(Icons.arrow_back),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (isAdmin) ...[
              _SectionHeader('Data'),
              _SettingsTile(
                icon: Icons.upload_file_rounded,
                title: 'Import CSV',
                subtitle:
                    'Import products, modifiers, users, or store info from CSV files',
                onTap: () => context.push('/settings/csv-import'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader('Store'),
              _SettingsTile(
                icon: Icons.store_outlined,
                title: 'Store Information',
                subtitle: 'Name, address, payment methods',
                onTap: () => context.push('/settings/store-info'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionHeader('Printer'),
            _SettingsTile(
              icon: Icons.print_outlined,
              title: 'Printer Setup',
              subtitle: 'Configure Bluetooth or built-in thermal printer',
              onTap: () => context.push('/settings/printer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
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
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: AppTextStyles.headingSm),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textDisabled,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}
