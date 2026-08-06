import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/services/print_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PrinterSetupScreen extends HookWidget {
  const PrinterSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedMac = useState<String?>(null);
    final savedName = useState<String?>(null);
    final devices = useState<List<BluetoothInfo>>([]);
    final scanning = useState(false);
    final connectingMac = useState<String?>(null);

    useEffect(() {
      PrintService.getSavedMac().then((v) => savedMac.value = v);
      PrintService.getSavedName().then((v) => savedName.value = v);
      return null;
    }, const []);

    Future<void> scan() async {
      scanning.value = true;
      try {
        devices.value = await PrintBluetoothThermal.pairedBluetooths;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        scanning.value = false;
      }
    }

    Future<void> connect(BluetoothInfo device) async {
      connectingMac.value = device.macAdress;
      try {
        final ok = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress,
        );
        if (ok) {
          await PrintService.savePrinter(device.macAdress, device.name);
          savedMac.value = device.macAdress;
          savedName.value = device.name;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connected to ${device.name}')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        connectingMac.value = null;
      }
    }

    Future<void> removePrinter() async {
      await PrintBluetoothThermal.disconnect;
      await PrintService.clearPrinter();
      savedMac.value = null;
      savedName.value = null;
    }

    final calibrating = useState<String?>(null);

    Future<void> printCalibration({required bool forceBluetooth}) async {
      calibrating.value = forceBluetooth ? 'bluetooth' : 'auto';
      try {
        final ok =
            forceBluetooth
                ? await PrintService.printCalibrationBluetooth()
                : await PrintService.printCalibration();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Calibration ruler sent' : 'Print failed'),
              backgroundColor: ok ? null : AppColors.error,
            ),
          );
        }
      } finally {
        calibrating.value = null;
      }
    }

    Future<void> printWidthProbe({required bool forceBluetooth}) async {
      calibrating.value = forceBluetooth ? 'probe-bluetooth' : 'probe-auto';
      try {
        final ok =
            forceBluetooth
                ? await PrintService.printWidthProbeBluetooth()
                : await PrintService.printWidthProbe();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Width probe sent' : 'Print failed'),
              backgroundColor: ok ? null : AppColors.error,
            ),
          );
        }
      } finally {
        calibrating.value = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Printer Setup'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Current printer ────────────────────────────────────────────
          _SectionCard(
            title: 'Current Printer',
            child:
                savedMac.value == null
                    ? Row(
                      children: [
                        const Icon(
                          Icons.print_disabled_outlined,
                          size: 32,
                          color: AppColors.textDisabled,
                        ),
                        const Gap(AppSpacing.md),
                        Text(
                          'No printer configured',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        const Icon(
                          Icons.print_rounded,
                          size: 32,
                          color: AppColors.success,
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                savedName.value ?? 'Unknown',
                                style: AppTextStyles.headingSm,
                              ),
                              Text(
                                savedMac.value!,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: removePrinter,
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),
          ),
          const Gap(AppSpacing.lg),

          // ── Calibration ────────────────────────────────────────────────
          _SectionCard(
            title: 'Calibration',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prints a numbered ruler. Read off the last full column '
                  'printed before the paper edge (or where it wraps) and '
                  'report it back so the row width can be corrected.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(AppSpacing.md),
                OutlinedButton.icon(
                  onPressed:
                      calibrating.value != null
                          ? null
                          : () => printCalibration(forceBluetooth: false),
                  icon: const Icon(Icons.straighten_rounded, size: 18),
                  label: Text(
                    calibrating.value == 'auto'
                        ? 'Printing...'
                        : 'Print Calibration Ruler',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSpacing.touchPreferred,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
                if (savedMac.value != null) ...[
                  const Gap(AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed:
                        calibrating.value != null
                            ? null
                            : () => printCalibration(forceBluetooth: true),
                    icon: const Icon(Icons.bluetooth_rounded, size: 18),
                    label: Text(
                      calibrating.value == 'bluetooth'
                          ? 'Printing...'
                          : 'Print Calibration Ruler (Bluetooth)',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.touchPreferred,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ],
                const Gap(AppSpacing.lg),
                Text(
                  'Width probe: prints W=50..59, each a line of that exact '
                  'length ending in "|". Find the highest W whose "|" is '
                  'still attached at the end of its line (not wrapped alone '
                  'onto the next line) — that\'s the printer\'s real '
                  'character capacity.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(AppSpacing.md),
                OutlinedButton.icon(
                  onPressed:
                      calibrating.value != null
                          ? null
                          : () => printWidthProbe(forceBluetooth: false),
                  icon: const Icon(Icons.rule_rounded, size: 18),
                  label: Text(
                    calibrating.value == 'probe-auto'
                        ? 'Printing...'
                        : 'Print Width Probe',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSpacing.touchPreferred,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
                if (savedMac.value != null) ...[
                  const Gap(AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed:
                        calibrating.value != null
                            ? null
                            : () => printWidthProbe(forceBluetooth: true),
                    icon: const Icon(Icons.bluetooth_rounded, size: 18),
                    label: Text(
                      calibrating.value == 'probe-bluetooth'
                          ? 'Printing...'
                          : 'Print Width Probe (Bluetooth)',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.touchPreferred,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          // ── Scan button ────────────────────────────────────────────────
          FilledButton.tonal(
            onPressed: scanning.value ? null : scan,
            style: FilledButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                AppSpacing.touchPreferred,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child:
                scanning.value
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_searching_rounded),
                        Gap(AppSpacing.sm),
                        Text('Scan Paired Devices'),
                      ],
                    ),
          ),

          // ── Device list ────────────────────────────────────────────────
          if (devices.value.isNotEmpty) ...[
            const Gap(AppSpacing.lg),
            Text(
              'PAIRED DEVICES',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const Gap(AppSpacing.sm),
            ...devices.value.map((device) {
              final isCurrent = device.macAdress == savedMac.value;
              final isConnecting = connectingMac.value == device.macAdress;
              return _DeviceTile(
                device: device,
                isCurrent: isCurrent,
                isConnecting: isConnecting,
                onTap:
                    (isConnecting || isCurrent) ? null : () => connect(device),
              );
            }),
          ],

          if (devices.value.isEmpty && !scanning.value) ...[
            const Gap(AppSpacing.xl),
            Center(
              child: Text(
                'Tap "Scan Paired Devices" to see available printers.\n'
                'Make sure Bluetooth is on and the printer is paired in system settings.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Gap(AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothInfo device;
  final bool isCurrent;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _DeviceTile({
    required this.device,
    required this.isCurrent,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            isCurrent
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              isCurrent
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          leading: Icon(
            Icons.print_rounded,
            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(device.name, style: AppTextStyles.headingSm),
          subtitle: Text(
            device.macAdress,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing:
              isConnecting
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : isCurrent
                  ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  )
                  : const Icon(
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
