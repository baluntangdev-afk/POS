import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/merchant_device_notifier.dart';
import 'device_registration_status_visual.dart';

/// Always-visible summary of this device's registration status, shown at the
/// top of the Store Information form. Renders nothing until the device has been
/// registered at least once.
class DeviceRegistrationStatusCard extends ConsumerWidget {
  const DeviceRegistrationStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(merchantDeviceNotifierProvider).value;
    if (state == null || state.deviceId == null) {
      return const SizedBox.shrink();
    }

    final visual = DeviceRegistrationStatusVisual.of(
      state.status,
      state.merchantName,
    );
    final busy = state.isRegistering;
    final merchant = state.merchantName?.trim() ?? '';

    // NOTE: a non-uniform `Border` cannot be combined with `borderRadius`
    // (Flutter assertion). Use a uniform status-tinted border instead.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.card,
        border: Border.all(color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visual.icon, color: visual.color, size: 22),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  visual.headline,
                  style: AppTextStyles.headingSm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (merchant.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              merchant,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const Gap(AppSpacing.sm),
          Text(
            visual.body,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  busy
                      ? null
                      : () =>
                          ref
                              .read(merchantDeviceNotifierProvider.notifier)
                              .refreshStatus(),
              icon:
                  busy
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(busy ? 'Checking…' : 'Check status'),
            ),
          ),
        ],
      ),
    );
  }
}
