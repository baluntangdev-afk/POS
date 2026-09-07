import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/setup_prompt_dialog.dart';

/// Normalised device-registration status buckets. `rejected` collapses into
/// [DeviceRegistrationStatus.deactivated]; anything unrecognised (or null) is
/// [DeviceRegistrationStatus.unknown].
enum DeviceRegistrationStatus { pending, approved, deactivated, unknown }

DeviceRegistrationStatus deviceRegistrationStatusFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pending':
      return DeviceRegistrationStatus.pending;
    case 'approved':
      return DeviceRegistrationStatus.approved;
    case 'deactivated':
    case 'rejected':
      return DeviceRegistrationStatus.deactivated;
    default:
      return DeviceRegistrationStatus.unknown;
  }
}

/// Visual treatment + copy for a device-registration status, shared by the
/// persistent status card and the one-time dialog.
class DeviceRegistrationStatusVisual {
  const DeviceRegistrationStatusVisual({
    required this.color,
    required this.icon,
    required this.headline,
    required this.dialogTitle,
    required this.dialogType,
    required this.primaryButtonText,
    required this.body,
  });

  final Color color;
  final IconData icon;

  /// Short label for the status card.
  final String headline;

  /// Title for the one-time dialog.
  final String dialogTitle;
  final SetupPromptType dialogType;
  final String primaryButtonText;

  /// One-sentence explanation. [merchant] is already interpolated.
  final String body;

  static DeviceRegistrationStatusVisual of(
    String? rawStatus,
    String? merchantName,
  ) {
    final merchant =
        (merchantName?.trim().isNotEmpty ?? false)
            ? merchantName!.trim()
            : 'your merchant account';
    final status = deviceRegistrationStatusFrom(rawStatus);
    switch (status) {
      case DeviceRegistrationStatus.pending:
        return DeviceRegistrationStatusVisual(
          color: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
          headline: 'Waiting for approval',
          dialogTitle: 'Device Pending Approval',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body:
              'This device was submitted to $merchant and is waiting for '
              'approval. You can keep using the POS in the meantime — live '
              'orders begin once it is approved.',
        );
      case DeviceRegistrationStatus.approved:
        return DeviceRegistrationStatusVisual(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          headline: 'Device approved',
          dialogTitle: 'Device Approved',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body:
              'This device is approved for $merchant. Live orders are now '
              'enabled.',
        );
      case DeviceRegistrationStatus.deactivated:
        return DeviceRegistrationStatusVisual(
          color: AppColors.error,
          icon: Icons.block_rounded,
          headline: 'Device deactivated',
          dialogTitle: 'Device Deactivated',
          dialogType: SetupPromptType.warning,
          primaryButtonText: 'OK',
          body:
              'This device\'s access to $merchant has been turned off. Live '
              'orders are paused. Contact your merchant administrator to '
              'restore access.',
        );
      case DeviceRegistrationStatus.unknown:
        final raw = rawStatus?.trim() ?? '';
        return DeviceRegistrationStatusVisual(
          color: AppColors.primary,
          icon: Icons.info_rounded,
          headline: raw.isEmpty ? 'Registration status' : 'Status: $raw',
          dialogTitle: 'Device Status',
          dialogType: SetupPromptType.info,
          primaryButtonText: 'Got it',
          body:
              raw.isEmpty
                  ? 'This device\'s registration status is not known yet.'
                  : 'This device\'s registration status is \'$raw\'.',
        );
    }
  }
}
