import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import 'export_backup_dialog.dart';
import 'import_backup_dialog.dart';

/// Admin/supervisor hub for full-device backup + migration. Reached from the
/// "Backup & Transfer" menu tile; the route itself is only listed for
/// admin/supervisor roles and every action re-checks with a supervisor PIN.
class DeviceTransferScreen extends ConsumerWidget {
  const DeviceTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          const TopAppBar(
            title: 'Backup & Transfer',
            subtitle: 'Move this device’s full data to another kiosk',
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(r.value<double>(kiosk: 40, tablet: 32, phone: 20)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoBanner(r: r),
                      SizedBox(height: r.value<double>(kiosk: 28, tablet: 22, phone: 16)),
                      _ActionCard(
                        r: r,
                        icon: Icons.download_rounded,
                        accent: ColorSet.primary,
                        title: 'Export Backup',
                        description:
                            'Save every user, product, transaction, report and setting on '
                            'this device to one encrypted file. Requires a passphrase you '
                            'choose — keep it safe, the file cannot be opened without it.',
                        cta: 'Start Export',
                        onTap: () => showExportBackupDialog(context),
                      ),
                      SizedBox(height: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
                      _ActionCard(
                        r: r,
                        icon: Icons.settings_backup_restore_rounded,
                        accent: ColorSet.danger,
                        title: 'Import & Restore',
                        description:
                            'Load a backup file onto this device. This permanently replaces '
                            'ALL current data — use it only when setting up a replacement '
                            'kiosk or restoring after a reinstall.',
                        cta: 'Start Restore',
                        onTap: () => showImportBackupDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.r});

  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
      decoration: BoxDecoration(
        color: ColorSet.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: ColorSet.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: ColorSet.warning, size: r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
          SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
          Expanded(
            child: Text(
              'Backup files contain staff PINs and customer + sales data. Store them '
              'somewhere secure and never share them.',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                color: ColorSet.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.r,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.cta,
    required this.onTap,
  });

  final ResponsiveValue r;
  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: POSColors.surfaceElevated,
      borderRadius: BorderRadius.circular(POSRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Container(
          padding: EdgeInsets.all(r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(POSRadius.xl),
            border: Border.all(color: POSColors.borderDefault),
            boxShadow: POSShadow.card,
          ),
          child: Row(
            children: [
              Container(
                width: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
                height: r.value<double>(kiosk: 56, tablet: 50, phone: 44),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
                child: Icon(icon, color: accent, size: r.value<double>(kiosk: 28, tablet: 24, phone: 22)),
              ),
              SizedBox(width: r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                        fontWeight: FontWeight.w700,
                        color: POSColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                        color: POSColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cta,
                          style: TextStyle(
                            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: accent, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
