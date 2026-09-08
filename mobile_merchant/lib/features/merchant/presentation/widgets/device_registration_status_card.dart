import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../state/merchant_notifier.dart';
import '../device_status_visual.dart';

/// Always-visible summary of this device's registration status, shown at the
/// top of the merchant settings form. Renders nothing until the once-per-launch
/// device probe ([deviceStartupProvider]) has resolved for a registered
/// merchant.
///
/// Ported from `mobile/`'s `DeviceRegistrationStatusCard` — the "Check status"
/// button re-runs the idempotent `POST /devices/register` probe so an approval
/// granted by the merchant admin is picked up without restarting the app.
class DeviceRegistrationStatusCard extends ConsumerStatefulWidget {
  const DeviceRegistrationStatusCard({super.key});

  @override
  ConsumerState<DeviceRegistrationStatusCard> createState() =>
      _DeviceRegistrationStatusCardState();
}

class _DeviceRegistrationStatusCardState
    extends ConsumerState<DeviceRegistrationStatusCard> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final result =
          await ref.read(merchantProvider.notifier).recheckDeviceStatus();
      if (!mounted) return;
      if (result.justApproved) {
        AppSnackbar.success(context, 'Device approved — you\'re all set.');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Couldn\'t check status. Try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(merchantProvider).value;
    final startup = ref.watch(deviceStartupProvider).value;
    if (merchant == null || startup == null) return const SizedBox.shrink();

    final visual = DeviceStatusVisual.of(startup.status, merchant.merchantName);
    final merchantName = merchant.merchantName.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: visual.color.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visual.icon, color: visual.color, size: 20),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  visual.headline,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (merchantName.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              merchantName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
          const Gap(AppSpacing.sm),
          Text(
            visual.body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _checking ? null : _check,
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_checking ? 'Checking…' : 'Check status'),
            ),
          ),
        ],
      ),
    );
  }
}
