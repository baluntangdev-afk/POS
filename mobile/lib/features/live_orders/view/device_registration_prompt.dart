import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/setup_prompt_dialog.dart';
import '../entities/merchant_device_state.dart';
import '../use_cases/device_registration_error.dart';
import 'device_registration_status_visual.dart';

// Module-level guards so that if more than one screen listens at once
// (dashboard setup flow + settings store-info screen), only the first
// reaction wins and dialogs never stack.
String? _shownStatusKey; // '<deviceId>|<status>'
DeviceRegistrationError? _shownError;

void handleMerchantDeviceOutcome(
  BuildContext context,
  MerchantDeviceState? previous,
  MerchantDeviceState? next,
) {
  if (next == null) return;

  // Only surface the dialog for a status that arrived from a live
  // register/refresh call this session — a `persistedStatus` rehydrated on
  // startup is shown by the persistent status card, not a popup.
  final registration = next.registration;
  final status = registration?.status.trim().toLowerCase();
  final deviceId = registration?.deviceId;
  if (registration != null &&
      status != null &&
      status.isNotEmpty &&
      deviceId != null) {
    final key = '$deviceId|$status';
    if (key != _shownStatusKey) {
      _shownStatusKey = key;
      _shownError = null;
      final visual = DeviceRegistrationStatusVisual.of(
        next.status,
        next.merchantName,
      );
      unawaited(
        showSetupPromptDialog(
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
      showSetupPromptDialog(
        context,
        type: SetupPromptType.error,
        title: 'Device Registration Failed',
        message:
            '${next.errorMessage ?? error.message}\n\n'
            'It will retry the next time store info is saved.',
        primaryButtonText: 'OK',
      ),
    );
  }
}
