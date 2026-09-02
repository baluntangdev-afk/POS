import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/setup_prompt_dialog.dart';
import '../entities/merchant_device_state.dart';
import '../use_cases/device_registration_error.dart';

// Module-level guards so that if more than one screen listens at once
// (dashboard setup flow + settings store-info screen), only the first
// reaction wins and dialogs never stack.
String? _promptedDeviceId;
DeviceRegistrationError? _snackedError;

/// Reacts to [MerchantDeviceState] transitions from a `ref.listen`. Shows the
/// "pending approval" dialog once per successful registration, and a
/// dismissible snackbar once per failure.
///
/// Nothing here blocks or gates the app — the device keeps operating whether
/// or not it has been approved.
void handleMerchantDeviceOutcome(
  BuildContext context,
  MerchantDeviceState? previous,
  MerchantDeviceState? next,
) {
  if (next == null) return;

  final registration = next.registration;
  if (registration != null && _promptedDeviceId != registration.deviceId) {
    _promptedDeviceId = registration.deviceId;
    _snackedError = null;
    unawaited(
      showSetupPromptDialog(
        context,
        type: SetupPromptType.info,
        title: 'Device Pending Approval',
        message:
            'This device has been submitted to your merchant account and is '
            'awaiting approval. You can keep using the POS as normal in the '
            'meantime.',
        primaryButtonText: 'Got it',
      ),
    );
    return;
  }

  final error = next.error;
  if (error != null && error != _snackedError && error != previous?.error) {
    _snackedError = error;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          '${error.message} It will retry the next time store info is saved.',
        ),
      ),
    );
  }
}
