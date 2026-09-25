import 'dart:async';

import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../widgets/message_dialog.dart';
import '../entities/merchant_device_state.dart';
import '../use_cases/device_registration_error.dart';
import 'device_registration_status_visual.dart';

String? _shownStatusKey; // '<deviceId>|<status>'
DeviceRegistrationError? _shownError;

typedef DeviceStatusToast = ({String message, Color color});

/// Toast content for the current device-registration [state]: the last
/// failed attempt's message when there is one, otherwise the status copy
/// (e.g. "waiting for approval"). `null` when the device has never
/// registered. Unlike [handleMerchantDeviceOutcome]'s one-time dialog, this
/// has no dedup — callers decide when it's shown (e.g. an explicit "Check
/// status" tap).
DeviceStatusToast? deviceStatusToastFor(MerchantDeviceState state) {
  if (!state.isRegistered) return null;
  final error = state.error;
  if (error != null) {
    return (message: state.errorMessage ?? error.message, color: ColorSet.danger);
  }
  final visual = DeviceRegistrationStatusVisual.of(state.status, state.merchantName);
  return (message: visual.body, color: visual.color);
}

/// Shows a one-time dialog for a fresh registration outcome: the approval
/// status the first time it's seen for a device, or a registration failure.
/// Deduped per `deviceId|status` (and per error) across the whole session, so
/// re-checks that return the same status stay quiet.
void handleMerchantDeviceOutcome(BuildContext context, MerchantDeviceState? previous, MerchantDeviceState? next) {
  if (next == null) return;
  final registration = next.registration;
  final status = registration?.status.trim().toLowerCase();
  final deviceId = registration?.deviceId;
  if (registration != null && status != null && status.isNotEmpty && deviceId != null) {
    final key = '$deviceId|$status';
    if (key != _shownStatusKey) {
      _shownStatusKey = key;
      _shownError = null;
      final visual = DeviceRegistrationStatusVisual.of(next.status, next.merchantName);
      unawaited(
        showMessageDialog(
          context,
          type: visual.dialogType,
          title: visual.dialogTitle,
          message: visual.body,
          primaryButtonText: visual.primaryButtonText,
        ),
      );
      return;
    }
  }

  final error = next.error;
  if (error != null && error != _shownError && error != previous?.error) {
    _shownError = error;
    unawaited(
      showMessageDialog(
        context,
        type: DialogType.error,
        title: 'Device Registration Failed',
        message:
            '${next.errorMessage ?? error.message}\n\n'
            'It will retry the next time the Kiosk ID is saved.',
      ),
    );
  }
}
