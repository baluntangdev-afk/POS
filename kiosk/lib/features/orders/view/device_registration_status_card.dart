import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../theme/pos_design.dart';
import '../state/merchant_device_notifier.dart';
import 'device_registration_prompt.dart';
import 'device_registration_status_visual.dart';

/// Always-visible summary of this kiosk's registration status, shown at the
/// top of the POS Terminal Details dialog. Renders nothing until the device
/// has been registered at least once.
class DeviceRegistrationStatusCard extends ConsumerWidget {
  const DeviceRegistrationStatusCard({super.key});

  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    await ref.read(merchantDeviceNotifierProvider.notifier).refreshStatus();
    if (!context.mounted) return;
    final result = ref.read(merchantDeviceNotifierProvider).value;
    final toast = result == null ? null : deviceStatusToastFor(result);
    if (toast == null) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(toast.message),
          backgroundColor: toast.color,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(merchantDeviceNotifierProvider).value;
    if (state == null || state.deviceId == null) {
      return const SizedBox.shrink();
    }

    final visual = DeviceRegistrationStatusVisual.of(state.status, state.merchantName);
    final busy = state.isRegistering;
    final merchant = state.merchantName?.trim() ?? '';

    // NOTE: a non-uniform `Border` cannot be combined with `borderRadius`
    // (Flutter assertion). Use a uniform status-tinted border instead.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: POSColors.surfaceBase,
        borderRadius: BorderRadius.circular(POSRadius.md),
        boxShadow: POSShadow.card,
        border: Border.all(color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visual.icon, color: visual.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visual.headline,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: POSColors.textPrimary),
                ),
              ),
            ],
          ),
          if (merchant.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              merchant,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(visual.body, style: const TextStyle(fontSize: 13, color: POSColors.textSecondary)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: busy ? null : () => _checkStatus(context, ref),
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(busy ? 'Checking…' : 'Check status'),
            ),
          ),
        ],
      ),
    );
  }
}
