import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../core/services/bluetooth_discovery_service.dart';
import '../../../core/services/bluetooth_printer_channel.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Why the last scan attempt didn't reach live discovery — drives which inline
/// prompt/action is shown below the scan button.
enum _ScanBlocker {
  none,
  bluetoothOff,
  permissionDenied,
  permissionPermanentlyDenied,
  locationServicesOff,
}

class PrinterSetupScreen extends HookWidget {
  const PrinterSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedMac = useState<String?>(null);
    final savedName = useState<String?>(null);
    final devices = useState<List<BluetoothInfo>>([]);
    final availableDevices = useState<List<BluetoothInfo>>([]);
    final scanning = useState(false);
    final scanBlocker = useState(_ScanBlocker.none);
    final connectingMac = useState<String?>(null);
    final pairingMac = useState<String?>(null);
    final pairErrors = useState<Map<String, String>>({});

    final discoverySub = useRef<StreamSubscription<BluetoothDiscoveryEvent>?>(
      null,
    );
    final pendingFound = useRef<List<BluetoothInfo>>([]);
    final flushTimer = useRef<Timer?>(null);
    final appLifecycleState = useAppLifecycleState();

    useEffect(() {
      PrintService.getSavedMac().then((v) => savedMac.value = v);
      PrintService.getSavedName().then((v) => savedName.value = v);
      return () {
        flushTimer.value?.cancel();
        discoverySub.value?.cancel();
        BluetoothDiscoveryService.stopDiscovery();
      };
    }, const []);

    void stopScan() {
      flushTimer.value?.cancel();
      flushTimer.value = null;
      discoverySub.value?.cancel();
      discoverySub.value = null;
      BluetoothDiscoveryService.stopDiscovery();
      scanning.value = false;
    }

    Future<void> scan() async {
      scanBlocker.value = _ScanBlocker.none;
      pairErrors.value = {};

      // Permission must be requested BEFORE any print_bluetooth_thermal call
      // (including isBluetoothEnabled below): on API 31+, that plugin's native
      // handler silently never resolves its result callback when
      // BLUETOOTH_CONNECT isn't granted yet, hanging this whole function
      // forever instead of erroring — so checking Bluetooth's on/off state
      // first would strand every fresh install with no permission prompt.
      final permissionState = await BluetoothDiscoveryService.requestPermissions();
      if (permissionState == BluetoothPermissionState.permanentlyDenied) {
        scanBlocker.value = _ScanBlocker.permissionPermanentlyDenied;
        return;
      }
      if (permissionState == BluetoothPermissionState.denied) {
        scanBlocker.value = _ScanBlocker.permissionDenied;
        return;
      }

      if (!await BluetoothDiscoveryService.isBluetoothEnabled()) {
        scanBlocker.value = _ScanBlocker.bluetoothOff;
        return;
      }

      if (await BluetoothDiscoveryService.needsLocationServices() &&
          !await BluetoothDiscoveryService.isLocationServicesEnabled()) {
        scanBlocker.value = _ScanBlocker.locationServicesOff;
        return;
      }

      // Release any open connection before scanning: the native connect()
      // refuses to reconnect while it still holds an open socket, which
      // would otherwise make every connect/pair tap during this scan fail
      // silently.
      await BluetoothPrinterChannel.disconnect();

      // The previously-connected device is no longer connected, so drop its
      // "current" highlight/disabled state here so it can be tapped again to
      // reconnect. This only resets this screen's display — the persisted
      // saved printer (used for printing elsewhere) is untouched.
      savedMac.value = null;
      savedName.value = null;

      devices.value = await PrintBluetoothThermal.pairedBluetooths;
      availableDevices.value = [];
      pendingFound.value = [];
      scanning.value = true;

      // Discovery events can arrive in a burst; flushing on a timer instead of
      // one setState per event keeps the list from causing a rebuild storm.
      flushTimer.value?.cancel();
      flushTimer.value = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (pendingFound.value.isEmpty) return;
        availableDevices.value = [...availableDevices.value, ...pendingFound.value];
        pendingFound.value = [];
      });

      discoverySub.value?.cancel();
      discoverySub.value = BluetoothDiscoveryService.startDiscovery().listen((
        event,
      ) {
        switch (event) {
          case DeviceFoundEvent(:final name, :final mac):
            final alreadyKnown =
                devices.value.any((d) => d.macAdress == mac) ||
                availableDevices.value.any((d) => d.macAdress == mac) ||
                pendingFound.value.any((d) => d.macAdress == mac);
            if (!alreadyKnown) {
              pendingFound.value = [
                ...pendingFound.value,
                BluetoothInfo(name: name, macAdress: mac),
              ];
            }
          case DiscoveryFinishedEvent():
            stopScan();
          case BondStateChangedEvent(:final mac, :final bonded):
            if (bonded) {
              availableDevices.value =
                  availableDevices.value
                      .where((d) => d.macAdress != mac)
                      .toList();
              PrintBluetoothThermal.pairedBluetooths.then(
                (v) => devices.value = v,
              );
            }
        }
      });
    }

    useEffect(() {
      if (appLifecycleState == AppLifecycleState.resumed &&
          scanBlocker.value == _ScanBlocker.bluetoothOff) {
        scan();
      }
      return null;
    }, [appLifecycleState]);

    Future<void> connect(BluetoothInfo device) async {
      connectingMac.value = device.macAdress;
      try {
        final ok = await BluetoothPrinterChannel.connect(device.macAdress);
        if (ok) {
          // Only used here to verify the printer is reachable before saving
          // it; printing opens its own connection per job (see
          // PrintService._printViaBluetooth). Leaving this one open blocks
          // every later connect() attempt because the native plugin refuses
          // to reconnect while it still holds an open socket.
          await BluetoothPrinterChannel.disconnect();
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

    Future<void> pairAndConnect(BluetoothInfo device) async {
      pairingMac.value = device.macAdress;
      pairErrors.value = {
        ...pairErrors.value,
      }..remove(device.macAdress);
      try {
        final bonded = await BluetoothDiscoveryService.pairAndWait(
          device.macAdress,
        );
        if (!bonded) {
          pairErrors.value = {
            ...pairErrors.value,
            device.macAdress: 'Pairing failed',
          };
          return;
        }
        availableDevices.value =
            availableDevices.value
                .where((d) => d.macAdress != device.macAdress)
                .toList();
        await connect(device);
        devices.value = await PrintBluetoothThermal.pairedBluetooths;
      } finally {
        pairingMac.value = null;
      }
    }

    Future<void> removePrinter() async {
      await BluetoothPrinterChannel.disconnect();
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
                    ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        Gap(AppSpacing.sm),
                        Text('Scanning...'),
                      ],
                    )
                    : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_searching_rounded),
                        Gap(AppSpacing.sm),
                        Text('Scan for Printers'),
                      ],
                    ),
          ),

          // ── Scan blocker prompt ───────────────────────────────────────
          if (scanBlocker.value != _ScanBlocker.none) ...[
            const Gap(AppSpacing.md),
            _ScanBlockerCard(
              blocker: scanBlocker.value,
              onTurnOnBluetooth: () async {
                await BluetoothDiscoveryService.requestEnableBluetooth();
              },
              onGrantPermission: scan,
              onOpenAppSettings: BluetoothDiscoveryService.openAppSettingsPage,
              onOpenLocationSettings:
                  BluetoothDiscoveryService.openLocationSettings,
            ),
          ],

          // ── Paired devices ────────────────────────────────────────────
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

          // ── Available (unpaired) devices ──────────────────────────────
          if (availableDevices.value.isNotEmpty) ...[
            const Gap(AppSpacing.lg),
            Text(
              'AVAILABLE DEVICES',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const Gap(AppSpacing.sm),
            ...availableDevices.value.map((device) {
              final isPairing = pairingMac.value == device.macAdress;
              return _DeviceTile(
                device: device,
                isCurrent: false,
                isConnecting: isPairing,
                errorText: pairErrors.value[device.macAdress],
                onTap: isPairing ? null : () => pairAndConnect(device),
              );
            }),
          ],

          if (devices.value.isEmpty &&
              availableDevices.value.isEmpty &&
              !scanning.value &&
              scanBlocker.value == _ScanBlocker.none) ...[
            const Gap(AppSpacing.xl),
            Center(
              child: Text(
                'Tap "Scan for Printers" to find nearby printers.\n'
                'Make sure Bluetooth is on and the printer is powered on.',
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

class _ScanBlockerCard extends StatelessWidget {
  const _ScanBlockerCard({
    required this.blocker,
    required this.onTurnOnBluetooth,
    required this.onGrantPermission,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final _ScanBlocker blocker;
  final VoidCallback onTurnOnBluetooth;
  final VoidCallback onGrantPermission;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final (String message, String actionLabel, VoidCallback action) =
        switch (blocker) {
          _ScanBlocker.bluetoothOff => (
            'Bluetooth is off. Turn it on to scan for printers.',
            'Turn On Bluetooth',
            onTurnOnBluetooth,
          ),
          _ScanBlocker.permissionDenied => (
            'Bluetooth permission is required to scan for printers.',
            'Grant Permission',
            onGrantPermission,
          ),
          _ScanBlocker.permissionPermanentlyDenied => (
            'Bluetooth permission was denied. Enable it from app settings '
                'to scan for printers.',
            'Open App Settings',
            onOpenAppSettings,
          ),
          _ScanBlocker.locationServicesOff => (
            'This Android version needs Location Services on to discover '
                'nearby Bluetooth printers.',
            'Open Location Settings',
            onOpenLocationSettings,
          ),
          _ScanBlocker.none => ('', '', onGrantPermission),
        };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),
          const Gap(AppSpacing.sm),
          TextButton(onPressed: action, child: Text(actionLabel)),
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
  final String? errorText;
  final VoidCallback? onTap;

  const _DeviceTile({
    required this.device,
    required this.isCurrent,
    required this.isConnecting,
    required this.onTap,
    this.errorText,
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
              errorText != null
                  ? AppColors.error.withValues(alpha: 0.4)
                  : isCurrent
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
            errorText ?? device.macAdress,
            style: AppTextStyles.bodySm.copyWith(
              color: errorText != null ? AppColors.error : AppColors.textSecondary,
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
