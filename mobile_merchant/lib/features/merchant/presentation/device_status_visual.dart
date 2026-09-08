import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/entities/device_startup_result.dart';

/// Normalised device-registration status buckets. `rejected` collapses into
/// [DeviceRegistrationStatus.deactivated]; anything unrecognised (or null) is
/// [DeviceRegistrationStatus.unknown].
///
/// Mirrors `mobile/`'s `DeviceRegistrationStatus` so both apps bucket and
/// describe device status identically.
enum DeviceRegistrationStatus { pending, approved, deactivated, unknown }

DeviceRegistrationStatus deviceRegistrationStatusFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case DeviceStatus.pending:
      return DeviceRegistrationStatus.pending;
    case DeviceStatus.approved:
      return DeviceRegistrationStatus.approved;
    case DeviceStatus.deactivated:
    case 'rejected':
      return DeviceRegistrationStatus.deactivated;
    default:
      return DeviceRegistrationStatus.unknown;
  }
}

/// Visual treatment + copy for a device-registration status, shared by the
/// persistent [DeviceRegistrationStatusCard] and the one-time
/// [DeviceStatusDialog]. Ported from `mobile/`'s
/// `DeviceRegistrationStatusVisual` so the two apps stay aligned.
class DeviceStatusVisual {
  const DeviceStatusVisual({
    required this.color,
    required this.icon,
    required this.headline,
    required this.dialogTitle,
    required this.primaryButtonText,
    required this.body,
  });

  final Color color;
  final IconData icon;

  /// Short label for the status card.
  final String headline;

  /// Title for the one-time dialog.
  final String dialogTitle;

  /// Dismiss-button label for the one-time dialog.
  final String primaryButtonText;

  /// One-sentence explanation. [merchant] is already interpolated.
  final String body;

  static DeviceStatusVisual of(String? rawStatus, String? merchantName) {
    final merchant = (merchantName?.trim().isNotEmpty ?? false)
        ? merchantName!.trim()
        : 'your merchant account';
    switch (deviceRegistrationStatusFrom(rawStatus)) {
      case DeviceRegistrationStatus.pending:
        return DeviceStatusVisual(
          color: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
          headline: 'Waiting for approval',
          dialogTitle: 'Device Pending Approval',
          primaryButtonText: 'Got it',
          body: 'This device was submitted to $merchant and is waiting for '
              'approval. You can keep using the app in the meantime — live '
              'orders begin once it is approved.',
        );
      case DeviceRegistrationStatus.approved:
        return DeviceStatusVisual(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          headline: 'Device approved',
          dialogTitle: 'Device Approved',
          primaryButtonText: 'Got it',
          body: 'This device is approved for $merchant. Live orders are now '
              'enabled.',
        );
      case DeviceRegistrationStatus.deactivated:
        return DeviceStatusVisual(
          color: AppColors.error,
          icon: Icons.block_rounded,
          headline: 'Device deactivated',
          dialogTitle: 'Device Deactivated',
          primaryButtonText: 'OK',
          body: 'This device\'s access to $merchant has been turned off. Live '
              'orders are paused. Contact your merchant administrator to '
              'restore access.',
        );
      case DeviceRegistrationStatus.unknown:
        final raw = rawStatus?.trim() ?? '';
        return DeviceStatusVisual(
          color: AppColors.primary,
          icon: Icons.info_outline_rounded,
          headline: raw.isEmpty ? 'Registration status' : 'Status: $raw',
          dialogTitle: 'Device Status',
          primaryButtonText: 'Got it',
          body: raw.isEmpty
              ? 'This device\'s registration status is not known yet.'
              : 'This device\'s registration status is \'$raw\'.',
        );
    }
  }
}
