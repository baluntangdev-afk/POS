import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../widgets/message_dialog.dart';
import '../use_cases/device_registration_status.dart';

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
  final DialogType dialogType;
  final String primaryButtonText;

  /// One-sentence explanation. [merchant] is already interpolated.
  final String body;

  static DeviceRegistrationStatusVisual of(String? rawStatus, String? merchantName) {
    final merchant = (merchantName?.trim().isNotEmpty ?? false) ? merchantName!.trim() : 'your merchant account';
    final status = deviceRegistrationStatusFrom(rawStatus);
    switch (status) {
      case DeviceRegistrationStatus.pending:
        return DeviceRegistrationStatusVisual(
          color: ColorSet.warning,
          icon: Icons.hourglass_top_rounded,
          headline: 'Waiting for approval',
          dialogTitle: 'Device Pending Approval',
          dialogType: DialogType.info,
          primaryButtonText: 'Got it',
          body:
              'This kiosk was submitted to $merchant and is waiting for '
              'approval. You can keep using the POS in the meantime — live '
              'orders begin once it is approved.',
        );
      case DeviceRegistrationStatus.approved:
        return DeviceRegistrationStatusVisual(
          color: ColorSet.success,
          icon: Icons.check_circle_rounded,
          headline: 'Device approved',
          dialogTitle: 'Device Approved',
          dialogType: DialogType.success,
          primaryButtonText: 'Got it',
          body: 'This kiosk is approved for $merchant. Live orders are now enabled.',
        );
      case DeviceRegistrationStatus.deactivated:
        return DeviceRegistrationStatusVisual(
          color: ColorSet.danger,
          icon: Icons.block_rounded,
          headline: 'Device deactivated',
          dialogTitle: 'Device Deactivated',
          dialogType: DialogType.warning,
          primaryButtonText: 'OK',
          body:
              "This kiosk's access to $merchant has been turned off. Live "
              'orders are paused. Contact your merchant administrator to '
              'restore access.',
        );
      case DeviceRegistrationStatus.unknown:
        final raw = rawStatus?.trim() ?? '';
        return DeviceRegistrationStatusVisual(
          color: ColorSet.primary,
          icon: Icons.info_rounded,
          headline: raw.isEmpty ? 'Registration status' : 'Status: $raw',
          dialogTitle: 'Device Status',
          dialogType: DialogType.info,
          primaryButtonText: 'Got it',
          body: raw.isEmpty
              ? "This kiosk's registration status is not known yet."
              : "This kiosk's registration status is '$raw'.",
        );
    }
  }
}
